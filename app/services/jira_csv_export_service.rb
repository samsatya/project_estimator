# Service for exporting epics to Jira-compatible CSV format
#
# This service generates a CSV file that can be imported into Jira to create:
# - Epic (parent container)
# - Stories (linked to the epic)
# - Sub-tasks (linked to their parent stories)
#
# Usage in Jira:
# 1. Go to Project Settings > Import
# 2. Choose "CSV" as the import source
# 3. Upload the generated CSV file
# 4. Map the CSV columns to Jira fields during import
# 5. After import, manually link Stories to the Epic using the Epic Link field
# 6. Link Sub-tasks to their parent Stories using the Parent field
#
# Note: Due to Jira CSV import limitations, hierarchical relationships
# need to be established after import by updating Epic Link and Parent fields
# with the actual Jira issue keys.
class JiraCsvExportService
  require 'csv'

  def initialize(epic)
    @epic = epic
  end

  def export_to_csv
    CSV.generate(headers: true) do |csv|
      # Header row - Jira CSV import format
      csv << [
        "Issue Type",           # Epic, Story, Sub-task
        "Summary",              # Issue title/name
        "Description",          # Issue description
        "Reporter",            # User who created the issue (optional)
        "Assignee",            # User assigned to the issue
        "Priority",            # Issue priority (optional, defaults to Medium)
        "Labels",              # Comma-separated labels
        "Epic Name",           # Epic name (for linking stories to epics)
        "Epic Link",           # Epic key (for linking stories to epics)
        "Story Points",        # Estimation points
        "Original Estimate",   # Time estimate in Jira format (e.g., "2h", "1d 4h")
        "Status",              # Issue status
        "Start Date",          # Custom field for start date
        "Due Date",            # Custom field for due date
        "Component/s",         # Project components
        "Fix Version/s",       # Release versions
        "Parent",              # Parent issue key (for sub-tasks)
        "Issue Links",         # Links to other issues
        "Custom Field (Task Type)" # Task type classification
      ]

      # Export the epic itself
      csv << [
        "Epic",                                    # Issue Type
        @epic.name,                               # Summary
        sanitize_description(@epic.description),   # Description
        "",                                       # Reporter (empty for now)
        "",                                       # Assignee (epics typically not assigned)
        "Medium",                                 # Priority
        generate_labels(@epic),                   # Labels
        @epic.name,                              # Epic Name
        "",                                      # Epic Link (empty for epic itself)
        "",                                      # Story Points (epics don't have points)
        "",                                      # Original Estimate
        "To Do",                                 # Status
        format_date(@epic.start_date),           # Start Date
        format_date(@epic.end_date),             # Due Date
        "",                                      # Component/s
        "",                                      # Fix Version/s
        "",                                      # Parent
        "",                                      # Issue Links
        ""                                       # Custom Field (Task Type)
      ]

      # Export stories belonging to this epic
      @epic.stories.order(:created_at).each do |story|
        csv << [
          "Story",                                 # Issue Type
          story.name,                             # Summary
          sanitize_description(story.description), # Description
          "",                                     # Reporter
          format_assignee(story.assigned_user),   # Assignee
          "Medium",                               # Priority
          generate_story_labels(story),           # Labels
          @epic.name,                            # Epic Name
          "",                                    # Epic Link (will be filled after epic creation)
          story.points,                          # Story Points
          format_time_estimate(story.estimated_hours), # Original Estimate
          format_status(story.status),           # Status
          format_date(story.start_date),         # Start Date
          format_date(story.end_date),           # Due Date
          format_component(story.task_type),     # Component/s
          "",                                    # Fix Version/s
          "",                                    # Parent
          "",                                    # Issue Links
          story.task_type                        # Custom Field (Task Type)
        ]

        # Export subtasks for this story
        story.subtasks.each do |subtask|
          csv << [
            "Sub-task",                            # Issue Type
            subtask.name,                         # Summary
            sanitize_description(subtask.description), # Description
            "",                                   # Reporter
            format_assignee(subtask.assigned_user), # Assignee
            "Medium",                             # Priority
            generate_subtask_labels(subtask),     # Labels
            @epic.name,                          # Epic Name
            "",                                  # Epic Link
            "",                                  # Story Points (subtasks don't have points)
            format_time_estimate(subtask.estimated_hours), # Original Estimate
            format_status(subtask.status),       # Status
            "",                                  # Start Date (inherit from story)
            "",                                  # Due Date (inherit from story)
            format_component(subtask.task_type), # Component/s
            "",                                  # Fix Version/s
            "",                                  # Parent (will be filled after story creation)
            "",                                  # Issue Links
            subtask.task_type                    # Custom Field (Task Type)
          ]
        end
      end
    end
  end

  private

  def sanitize_description(description)
    return "" if description.blank?
    # Remove or escape characters that might cause CSV parsing issues
    description.to_s.strip.gsub(/[\r\n]+/, ' ').gsub(/,/, ';').gsub(/"/, "'")
  end

  def format_assignee(user)
    return "" unless user
    # Return email address for Jira user identification
    user.email.present? ? user.email : user.name
  end

  def format_status(status)
    return "To Do" if status.blank?

    case status.to_s.downcase
    when 'not_started', 'new', 'open'
      'To Do'
    when 'in_progress', 'active', 'working'
      'In Progress'
    when 'completed', 'done', 'closed', 'resolved'
      'Done'
    when 'blocked', 'on_hold'
      'Blocked'
    else
      status.to_s.titleize
    end
  end

  def format_date(date)
    return "" unless date
    date.strftime("%d/%b/%y") # Jira date format: 01/Jan/25
  end

  def format_time_estimate(hours)
    return "" unless hours && hours > 0

    # Convert decimal hours to Jira time format
    if hours < 1
      "#{(hours * 60).round}m" # Convert to minutes for sub-hour estimates
    elsif hours.to_i == hours
      "#{hours.to_i}h" # Whole hours
    else
      whole_hours = hours.to_i
      remaining_minutes = ((hours - whole_hours) * 60).round
      if remaining_minutes > 0
        "#{whole_hours}h #{remaining_minutes}m"
      else
        "#{whole_hours}h"
      end
    end
  end

  def generate_labels(epic)
    labels = ["epic-export"]
    labels << "project-#{@epic.project.name.parameterize}" if @epic.project&.name&.present?
    labels.join(",")
  end

  def generate_story_labels(story)
    labels = ["story-export"]
    labels << "#{story.points}-points" if story.points
    labels << "#{story.task_type.parameterize}" if story.task_type.present?
    labels.join(",")
  end

  def generate_subtask_labels(subtask)
    labels = ["subtask-export"]
    labels << "#{subtask.task_type.parameterize}" if subtask.task_type.present?
    labels.join(",")
  end

  def format_component(task_type)
    return "" unless task_type.present?
    # Map task types to Jira components
    case task_type.to_s.downcase
    when 'backend', 'development'
      'Backend'
    when 'ui', 'frontend'
      'Frontend'
    when 'testing', 'test'
      'QA'
    when 'design'
      'Design'
    when 'research'
      'Research'
    when 'documentation'
      'Documentation'
    when 'infra', 'infrastructure'
      'Infrastructure'
    else
      task_type.titleize
    end
  end
end