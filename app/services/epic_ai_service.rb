class EpicAiService
  attr_reader :ai_service, :epic

  def initialize(epic)
    @epic = epic
    @ai_service = AiService.new(@epic.project)
  end

  # Refine epic name and description using AI
  def refine
    return { success: false, error: "AI service is not enabled" } unless @ai_service.enabled?

    prompt = build_refinement_prompt
    system_prompt = "You are a product management expert specializing in agile software development. Your task is to refine epic descriptions to be clear, actionable, and valuable."

    begin
      response = @ai_service.invoke(prompt, system_prompt: system_prompt)
      parsed = @ai_service.parse_json_response(response)

      {
        success: true,
        refined_name: parsed["name"],
        refined_description: parsed["description"],
        suggestions: parsed["suggestions"] || []
      }
    rescue AiService::BedrockError, AiService::InvalidResponseError => e
      Rails.logger.error "Epic AI refinement failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  # Generate stories from epic description
  def generate_stories
    return { success: false, error: "AI service is not enabled" } unless @ai_service.enabled?

    prompt = build_story_generation_prompt
    system_prompt = "You are an agile development expert. Break down epics into well-defined user stories that are independently deliverable and properly sized."

    begin
      response = @ai_service.invoke(prompt, system_prompt: system_prompt, max_tokens: 4096)
      parsed = @ai_service.parse_json_response(response)

      stories = parsed["stories"] || parsed
      stories = [ stories ] unless stories.is_a?(Array)

      {
        success: true,
        stories: stories.map { |s| normalize_story(s) }
      }
    rescue AiService::BedrockError, AiService::InvalidResponseError => e
      Rails.logger.error "Story generation failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  private

  def build_refinement_prompt
    <<~PROMPT
      Refine this epic for a software project:

      Epic Name: #{@epic.name}
      Description: #{@epic.description || 'No description provided'}
      Project: #{@epic.project.name}

      Please provide:
      1. An improved, concise epic name (max 80 characters)
      2. An enhanced description that includes:
         - Clear objective and scope
         - User value and business impact
         - High-level acceptance criteria
         - Success metrics (if applicable)
      3. Any suggestions for breaking down or improving the epic

      Return your response as JSON in this exact format:
      {
        "name": "Improved epic name",
        "description": "Enhanced description with objective, value, criteria, and metrics",
        "suggestions": ["Optional suggestion 1", "Optional suggestion 2"]
      }
    PROMPT
  end

  def build_story_generation_prompt
    <<~PROMPT
      Break down this epic into user stories for a software development project:

      Epic: #{@epic.name}
      Description: #{@epic.description || 'No description provided'}
      Project: #{@epic.project.name}
      Project Context: #{@epic.project.description || 'No additional context'}

      Generate 5-15 user stories that:
      - Are independently deliverable
      - Follow the "As a [user], I want [goal], so that [benefit]" format when appropriate
      - Include clear acceptance criteria
      - Have appropriate story points (1, 2, 3, 5, 8, 13, or 21)
      - Specify task type (Backend, Frontend, Full-stack, Testing, Design, or Research)

      Return your response as JSON in this exact format:
      {
        "stories": [
          {
            "name": "Story name",
            "description": "Detailed description with acceptance criteria",
            "points": 5,
            "task_type": "Backend"
          }
        ]
      }

      Ensure all story points are from the Fibonacci sequence: 1, 2, 3, 5, 8, 13, 21
      Ensure task_type is one of: Backend, Frontend, Full-stack, Testing, Design, Research
    PROMPT
  end

  def normalize_story(story_data)
    {
      name: story_data["name"]&.strip,
      description: story_data["description"]&.strip,
      points: normalize_points(story_data["points"]),
      task_type: normalize_task_type(story_data["task_type"])
    }
  end

  def normalize_points(points)
    valid_points = [ 1, 2, 3, 5, 8, 13, 21 ]
    points = points.to_i

    # Find closest valid point
    valid_points.min_by { |p| (p - points).abs }
  end

  def normalize_task_type(task_type)
    valid_types = [ "Backend", "Frontend", "Full-stack", "Testing", "Design", "Research" ]
    task_type = task_type&.strip

    # Case-insensitive match
    valid_types.find { |t| t.downcase == task_type&.downcase } || "Backend"
  end
end
