class AssignmentSuggester
  def initialize(project, story_or_subtask)
    @project = project
    @item = story_or_subtask
    @required_skill = extract_required_skill
  end

  def suggest
    return [] if @project.users.empty?

    scored_users = @project.users.map do |user|
      {
        user: user,
        score: calculate_score(user)
      }
    end

    scored_users.sort_by { |u| -u[:score] }
  end

  def best_match
    suggestions = suggest
    suggestions.first&.dig(:user)
  end

  private

  def extract_required_skill
    # First check if task_type is explicitly set
    if @item.respond_to?(:task_type) && @item.task_type.present?
      case @item.task_type
      when "UI"
        return "Frontend"
      when "Backend"
        return "Backend"
      when "Infra"
        return "DevOps"
      when "Test"
        return "QA"
      end
    end
    
    # Try to infer skill from story/subtask name/description
    # This is a simple implementation - can be enhanced with ML or tags
    text = "#{@item.name} #{@item.description}".downcase
    
    if text.match?(/frontend|ui|ux|design|react|vue|angular|css|html/)
      "Frontend"
    elsif text.match?(/backend|api|server|database|rails|python|java/)
      "Backend"
    elsif text.match?(/devops|deploy|infrastructure|docker|kubernetes/)
      "DevOps"
    elsif text.match?(/test|qa|quality|testing/)
      "QA"
    elsif text.match?(/full.?stack|fullstack/)
      "Full-stack"
    else
      nil
    end
  end

  def calculate_score(user)
    score = 0

    # Primary strength match gets highest weight
    if user.primary_strength == @required_skill
      score += 100
    elsif user.secondary_strength == @required_skill
      score += 50
    end

    # If no specific skill required, prefer users with less workload
    unless @required_skill
      current_workload = calculate_current_workload(user)
      score += (100 - [current_workload, 100].min) # Inverse of workload
    end

    # Consider current workload (lower is better)
    current_workload = calculate_current_workload(user)
    score -= current_workload * 0.5

    # Prefer users with capacity
    if user.capacity && user.capacity > 0
      score += 10
    end

    score
  end

  def calculate_current_workload(user)
    # Calculate hours assigned to this user in the project
    user_stories = user.assigned_stories.where(epic_id: @project.epics.pluck(:id))
    user_subtasks = user.assigned_subtasks.where(story_id: @project.stories.pluck(:id))
    
    story_points = user_stories.sum(:points) || 0
    story_hours = story_points * @project.points_to_hours_conversion
    subtask_hours = user_subtasks.sum(:estimated_hours) || 0
    
    total_hours = story_hours + subtask_hours
    
    # Normalize by capacity if available
    if user.capacity && user.capacity > 0
      (total_hours / user.capacity * 100).round(2)
    else
      total_hours
    end
  end
end

