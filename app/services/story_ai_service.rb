class StoryAiService
  attr_reader :ai_service, :story

  def initialize(story)
    @story = story
    @ai_service = AiService.new(@story.epic.project)
  end

  # Refine story name and description using AI
  def refine
    return { success: false, error: "AI service is not enabled" } unless @ai_service.enabled?

    prompt = build_refinement_prompt
    system_prompt = "You are an agile development expert. Refine user stories to be clear, testable, and properly sized."

    begin
      response = @ai_service.invoke(prompt, system_prompt: system_prompt)
      parsed = @ai_service.parse_json_response(response)

      {
        success: true,
        refined_name: parsed["name"],
        refined_description: parsed["description"],
        suggested_points: normalize_points(parsed["suggested_points"]),
        suggested_task_type: normalize_task_type(parsed["task_type"])
      }
    rescue AiService::BedrockError, AiService::InvalidResponseError => e
      Rails.logger.error "Story AI refinement failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  # Generate subtasks from story description
  def generate_subtasks
    return { success: false, error: "AI service is not enabled" } unless @ai_service.enabled?

    prompt = build_subtask_generation_prompt
    system_prompt = "You are a technical lead breaking down user stories into actionable development tasks."

    begin
      response = @ai_service.invoke(prompt, system_prompt: system_prompt, max_tokens: 3000)
      parsed = @ai_service.parse_json_response(response)

      subtasks = parsed["subtasks"] || parsed
      subtasks = [ subtasks ] unless subtasks.is_a?(Array)

      {
        success: true,
        subtasks: subtasks.map { |s| normalize_subtask(s) }
      }
    rescue AiService::BedrockError, AiService::InvalidResponseError => e
      Rails.logger.error "Subtask generation failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  # Suggest story points based on description
  def suggest_points
    return { success: false, error: "AI service is not enabled" } unless @ai_service.enabled?

    prompt = build_points_suggestion_prompt
    system_prompt = "You are an experienced agile estimator. Analyze stories and suggest appropriate story points."

    begin
      response = @ai_service.invoke(prompt, system_prompt: system_prompt, max_tokens: 500)
      parsed = @ai_service.parse_json_response(response)

      {
        success: true,
        suggested_points: normalize_points(parsed["points"]),
        reasoning: parsed["reasoning"]
      }
    rescue AiService::BedrockError, AiService::InvalidResponseError => e
      Rails.logger.error "Points suggestion failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  private

  def build_refinement_prompt
    <<~PROMPT
      Refine this user story for a software development project:

      Story Name: #{@story.name}
      Description: #{@story.description || 'No description provided'}
      Epic: #{@story.epic.name}
      Current Points: #{@story.points || 'Not set'}

      Please provide:
      1. An improved, concise story name (max 100 characters)
      2. An enhanced description that includes:
         - Clear user story format (As a... I want... So that...)
         - Detailed acceptance criteria
         - Any technical considerations
      3. Suggested story points (1, 2, 3, 5, 8, 13, or 21)
      4. Suggested task type (Backend, Frontend, Full-stack, Testing, Design, or Research)

      Return your response as JSON in this exact format:
      {
        "name": "Improved story name",
        "description": "Enhanced description with user story format and acceptance criteria",
        "suggested_points": 5,
        "task_type": "Backend"
      }
    PROMPT
  end

  def build_subtask_generation_prompt
    <<~PROMPT
      Break down this user story into development subtasks:

      Story: #{@story.name}
      Description: #{@story.description || 'No description provided'}
      Story Points: #{@story.points}
      Epic: #{@story.epic.name}

      Generate 3-10 subtasks that:
      - Are specific, actionable development tasks
      - Include estimated hours (be realistic)
      - Cover all aspects: implementation, testing, documentation
      - Are ordered logically

      Return your response as JSON in this exact format:
      {
        "subtasks": [
          {
            "name": "Subtask name",
            "description": "Detailed description of what needs to be done",
            "estimated_hours": 4,
            "task_type": "Backend"
          }
        ]
      }

      Ensure task_type is one of: Backend, Frontend, Full-stack, Testing, Design, Research
    PROMPT
  end

  def build_points_suggestion_prompt
    <<~PROMPT
      Analyze this user story and suggest appropriate story points:

      Story: #{@story.name}
      Description: #{@story.description || 'No description provided'}
      Epic: #{@story.epic.name}

      Consider:
      - Complexity of implementation
      - Amount of work required
      - Uncertainty and risk
      - Dependencies

      Story points scale (Fibonacci):
      - 1: Trivial change, < 2 hours
      - 2: Simple task, 2-4 hours
      - 3: Small feature, 4-8 hours
      - 5: Medium feature, 1-2 days
      - 8: Large feature, 2-3 days
      - 13: Complex feature, 3-5 days
      - 21: Very complex, should be broken down

      Return your response as JSON in this exact format:
      {
        "points": 5,
        "reasoning": "Brief explanation of why this point value"
      }
    PROMPT
  end

  def normalize_subtask(subtask_data)
    {
      name: subtask_data["name"]&.strip,
      description: subtask_data["description"]&.strip,
      estimated_hours: normalize_hours(subtask_data["estimated_hours"]),
      task_type: normalize_task_type(subtask_data["task_type"])
    }
  end

  def normalize_points(points)
    valid_points = [ 1, 2, 3, 5, 8, 13, 21 ]
    points = points.to_i

    # Find closest valid point
    valid_points.min_by { |p| (p - points).abs }
  end

  def normalize_hours(hours)
    hours = hours.to_f
    # Ensure hours are reasonable (0.5 to 40)
    [ [ hours, 0.5 ].max, 40 ].min
  end

  def normalize_task_type(task_type)
    valid_types = [ "Backend", "Frontend", "Full-stack", "Testing", "Design", "Research" ]
    task_type = task_type&.strip

    # Case-insensitive match
    valid_types.find { |t| t.downcase == task_type&.downcase } || "Backend"
  end
end
