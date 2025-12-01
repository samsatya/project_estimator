class EstimationCalculator
  def initialize(project)
    @project = project
  end

  def total_story_points
    @project.stories.sum(:points) || 0
  end

  def total_story_hours
    total_story_points * @project.points_to_hours_conversion
  end

  def pr_review_hours
    total_story_hours * @project.pr_review_time_percentage
  end

  def product_testing_hours
    total_story_hours * @project.product_testing_time_percentage
  end

  def business_testing_hours
    total_story_hours * @project.business_testing_time_percentage
  end

  def total_hours
    total_story_hours + pr_review_hours + product_testing_hours + business_testing_hours
  end

  def estimated_days(working_hours_per_day: 8)
    (total_hours / working_hours_per_day).ceil
  end

  def estimated_weeks(working_days_per_week: 5)
    (estimated_days.to_f / working_days_per_week).ceil
  end

  def breakdown
    {
      story_points: total_story_points,
      story_hours: total_story_hours.round(2),
      pr_review_hours: pr_review_hours.round(2),
      product_testing_hours: product_testing_hours.round(2),
      business_testing_hours: business_testing_hours.round(2),
      total_hours: total_hours.round(2),
      estimated_days: estimated_days,
      estimated_weeks: estimated_weeks
    }
  end

  def by_epic
    @project.epics.includes(:stories).map do |epic|
      epic_points = epic.stories.sum(:points) || 0
      epic_hours = epic_points * @project.points_to_hours_conversion
      {
        epic: epic,
        points: epic_points,
        hours: epic_hours.round(2)
      }
    end
  end

  def by_team_member
    result = {}
    @project.users.each do |user|
      user_stories = user.assigned_stories.where(epic_id: @project.epics.pluck(:id))
      user_subtasks = user.assigned_subtasks.where(story_id: @project.stories.pluck(:id))
      
      story_points = user_stories.sum(:points) || 0
      story_hours = story_points * @project.points_to_hours_conversion
      subtask_hours = user_subtasks.sum(:estimated_hours) || 0
      
      result[user.id] = {
        user: user,
        story_points: story_points,
        story_hours: story_hours.round(2),
        subtask_hours: subtask_hours.round(2),
        total_hours: (story_hours + subtask_hours).round(2)
      }
    end
    result
  end
end

