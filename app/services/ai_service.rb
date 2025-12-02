class AiService
  class BedrockError < StandardError; end
  class RateLimitError < StandardError; end
  class InvalidResponseError < StandardError; end

  attr_reader :config, :client

  def initialize(project_config = nil)
    @project_config = project_config
    @config = load_config
    @client = initialize_client if enabled?
  end

  def enabled?
    if @project_config&.aws_configured?
      true
    else
      @config[:enabled] && credentials_present?
    end
  end

  # Main method to invoke Bedrock with a prompt
  def invoke(prompt, system_prompt: nil, max_tokens: nil)
    raise BedrockError, "AI service is not enabled" unless enabled?

    check_rate_limit!

    # Check cache first
    cache_key = generate_cache_key(prompt, system_prompt)
    cached_response = Rails.cache.read(cache_key)
    return cached_response if cached_response

    response = invoke_with_retry(prompt, system_prompt, max_tokens)

    # Cache the response
    Rails.cache.write(cache_key, response, expires_in: @config[:cache_ttl])

    response
  rescue Aws::BedrockRuntime::Errors::ThrottlingException => e
    raise RateLimitError, "Rate limit exceeded: #{e.message}"
  rescue Aws::BedrockRuntime::Errors::ServiceError => e
    raise BedrockError, "Bedrock service error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "AI Service Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    raise BedrockError, "Unexpected error: #{e.message}"
  end

  # Parse JSON response from Claude
  def parse_json_response(response)
    # Extract JSON from markdown code blocks if present
    json_text = response.strip
    json_text = json_text.match(/```json\n(.*?)\n```/m)&.captures&.first || json_text
    json_text = json_text.match(/```\n(.*?)\n```/m)&.captures&.first || json_text

    JSON.parse(json_text)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response as JSON: #{response}"
    raise InvalidResponseError, "Invalid JSON response from AI: #{e.message}"
  end

  private

  def load_config
    config_file = Rails.root.join("config", "bedrock.yml")
    yaml_config = YAML.load_file(config_file)[Rails.env]
    yaml_config.deep_symbolize_keys
  rescue Errno::ENOENT
    Rails.logger.warn "Bedrock config file not found, AI features disabled"
    { enabled: false }
  end

  def initialize_client
    Aws::BedrockRuntime::Client.new(
      region: aws_region,
      credentials: aws_credentials,
      retry_limit: @config[:retry_attempts],
      http_read_timeout: @config[:timeout]
    )
  rescue StandardError => e
    Rails.logger.error "Failed to initialize Bedrock client: #{e.message}"
    nil
  end

  def aws_credentials
    if @project_config&.aws_configured?
      Aws::Credentials.new(
        @project_config.aws_access_key_id,
        @project_config.aws_secret_access_key
      )
    else
      Aws::Credentials.new(
        Rails.application.credentials.dig(:aws, :access_key_id),
        Rails.application.credentials.dig(:aws, :secret_access_key)
      )
    end
  end

  def aws_region
    if @project_config&.aws_configured?
      @project_config.aws_region
    else
      @config[:region]
    end
  end

  def model_id
    if @project_config&.aws_configured? && @project_config.aws_model_id.present?
      @project_config.aws_model_id
    else
      @config[:model_id]
    end
  end

  def credentials_present?
    Rails.application.credentials.dig(:aws, :access_key_id).present? &&
      Rails.application.credentials.dig(:aws, :secret_access_key).present?
  end

  def invoke_with_retry(prompt, system_prompt, max_tokens)
    attempts = 0
    max_attempts = @config[:retry_attempts]

    begin
      attempts += 1
      invoke_bedrock(prompt, system_prompt, max_tokens)
    rescue Aws::BedrockRuntime::Errors::ThrottlingException => e
      if attempts < max_attempts
        sleep(@config[:retry_delay] * attempts)
        retry
      else
        raise
      end
    end
  end

  def invoke_bedrock(prompt, system_prompt, max_tokens)
    messages = [
      {
        role: "user",
        content: [ { type: "text", text: prompt } ]
      }
    ]

    request_body = {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: max_tokens || @config[:max_tokens],
      messages: messages,
      temperature: @config[:temperature]
    }

    # Add system prompt if provided
    request_body[:system] = [ { type: "text", text: system_prompt } ] if system_prompt

    response = @client.invoke_model({
      model_id: model_id,
      body: request_body.to_json,
      content_type: "application/json",
      accept: "application/json"
    })

    response_body = JSON.parse(response.body.read)

    # Extract text from Claude's response
    response_body.dig("content", 0, "text") || raise(InvalidResponseError, "No text in response")
  end

  def check_rate_limit!
    # Simple rate limiting using Rails cache
    minute_key = "ai_rate_limit:minute:#{Time.current.strftime('%Y%m%d%H%M')}"
    hour_key = "ai_rate_limit:hour:#{Time.current.strftime('%Y%m%d%H')}"

    minute_count = Rails.cache.read(minute_key) || 0
    hour_count = Rails.cache.read(hour_key) || 0

    if minute_count >= @config.dig(:rate_limit, :requests_per_minute)
      raise RateLimitError, "Rate limit exceeded: too many requests per minute"
    end

    if hour_count >= @config.dig(:rate_limit, :requests_per_hour)
      raise RateLimitError, "Rate limit exceeded: too many requests per hour"
    end

    # Increment counters
    Rails.cache.write(minute_key, minute_count + 1, expires_in: 60)
    Rails.cache.write(hour_key, hour_count + 1, expires_in: 3600)
  end

  def generate_cache_key(prompt, system_prompt)
    content = "#{system_prompt}||#{prompt}"
    "ai_cache:#{Digest::SHA256.hexdigest(content)}"
  end
end
