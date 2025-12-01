class BulkUploadService
  attr_reader :epic, :errors, :imported_count

  def initialize(epic)
    @epic = epic
    @errors = []
    @imported_count = { stories: 0, subtasks: 0 }
  end

  def import_from_csv(csv_content)
    
    begin
      csv = CSV.parse(csv_content, headers: true, header_converters: :symbol)
      
      if csv.headers.empty?
        @errors << "CSV file is empty or invalid"
        return false
      end

      # Validate required headers
      required_headers = [:story_name, :story_points]
      missing_headers = required_headers - csv.headers
      
      if missing_headers.any?
        @errors << "Missing required columns: #{missing_headers.join(', ')}"
        return false
      end

      current_story = nil
      
      csv.each_with_index do |row, index|
        row_number = index + 2 # +2 because CSV is 1-indexed and we skip header
        
        # Process story row (if story_name is present)
        if row[:story_name].present?
          story_name = row[:story_name].to_s.strip
          story_points = parse_points(row[:story_points])
          story_description = row[:story_description]&.to_s&.strip
          story_assigned_to = row[:story_assigned_to]&.to_s&.strip
          story_status = row[:story_status]&.to_s&.strip&.downcase
          story_task_type = row[:story_task_type]&.to_s&.strip

          if story_name.blank?
            @errors << "Row #{row_number}: Story name cannot be blank"
            next
          end

          if story_points.nil?
            @errors << "Row #{row_number}: Invalid story points. Must be one of: 1, 2, 3, 5, 8, 13, 21"
            next
          end

          # Create or find story
          current_story = @epic.stories.find_or_initialize_by(name: story_name)
          current_story.points = story_points
          current_story.description = story_description if story_description.present?
          current_story.status = story_status if story_status.present?
          current_story.task_type = story_task_type if story_task_type.present? && Story::TASK_TYPES.include?(story_task_type)
          
          # Assign user if provided
          if story_assigned_to.present?
            user = User.find_by("LOWER(name) = ? OR LOWER(email) = ?", story_assigned_to.downcase, story_assigned_to.downcase)
            current_story.assigned_user = user if user
          end

          is_new_record = current_story.new_record?
          
          unless current_story.save
            @errors << "Row #{row_number}: Story '#{story_name}' - #{current_story.errors.full_messages.join(', ')}"
            next
          end

          @imported_count[:stories] += 1 if is_new_record
        end

        # Process subtask row (if subtask_name is present and we have a current story)
        if row[:subtask_name].present?
          if current_story.nil?
            @errors << "Row #{row_number}: Subtask requires a story. Please provide story_name in the same or previous row."
            next
          end

          subtask_name = row[:subtask_name].to_s.strip
          subtask_hours = parse_hours(row[:subtask_estimated_hours])
          subtask_description = row[:subtask_description]&.to_s&.strip
          subtask_assigned_to = row[:subtask_assigned_to]&.to_s&.strip
          subtask_status = row[:subtask_status]&.to_s&.strip&.downcase
          subtask_task_type = row[:subtask_task_type]&.to_s&.strip

          if subtask_name.blank?
            @errors << "Row #{row_number}: Subtask name cannot be blank"
            next
          end

          # Create subtask
          subtask = current_story.subtasks.find_or_initialize_by(name: subtask_name)
          subtask.estimated_hours = subtask_hours if subtask_hours
          subtask.description = subtask_description if subtask_description.present?
          subtask.status = subtask_status if subtask_status.present?
          subtask.task_type = subtask_task_type if subtask_task_type.present? && Subtask::TASK_TYPES.include?(subtask_task_type)
          
          # Assign user if provided
          if subtask_assigned_to.present?
            user = User.find_by("LOWER(name) = ? OR LOWER(email) = ?", subtask_assigned_to.downcase, subtask_assigned_to.downcase)
            subtask.assigned_user = user if user
          end

          is_new_subtask = subtask.new_record?

          unless subtask.save
            @errors << "Row #{row_number}: Subtask '#{subtask_name}' - #{subtask.errors.full_messages.join(', ')}"
            next
          end

          @imported_count[:subtasks] += 1 if is_new_subtask
        end
      end

      @errors.empty?
    rescue CSV::MalformedCSVError => e
      @errors << "Invalid CSV format: #{e.message}"
      false
    rescue StandardError => e
      @errors << "Error processing CSV: #{e.message}"
      false
    end
  end

  def self.generate_template
    
    CSV.generate(headers: true) do |csv|
      # Header row
      csv << [
        "Story Name",
        "Story Points",
        "Story Description",
        "Story Assigned To",
        "Story Status",
        "Story Task Type",
        "Subtask Name",
        "Subtask Estimated Hours",
        "Subtask Description",
        "Subtask Assigned To",
        "Subtask Status",
        "Subtask Task Type"
      ]
      
      # Example rows
      csv << [
        "User Authentication",
        "5",
        "Implement login and registration",
        "john@example.com",
        "not_started",
        "Backend",
        "Create login form",
        "4",
        "Design and implement login UI",
        "jane@example.com",
        "not_started",
        "UI"
      ]
      
      csv << [
        "",
        "",
        "",
        "",
        "",
        "",
        "Create registration form",
        "6",
        "Design and implement registration UI",
        "jane@example.com",
        "not_started",
        "UI"
      ]
      
      csv << [
        "User Dashboard",
        "8",
        "Build user dashboard",
        "bob@example.com",
        "in_progress",
        "Full-stack",
        "Design dashboard layout",
        "8",
        "Create wireframes and design",
        "alice@example.com",
        "completed",
        "UI"
      ]
    end
  end

  private

  def parse_points(value)
    return nil if value.blank?
    
    points = value.to_s.strip.to_i
    Story::FIBONACCI_POINTS.include?(points) ? points : nil
  end

  def parse_hours(value)
    return nil if value.blank?
    
    hours = value.to_s.strip.to_f
    hours > 0 ? hours : nil
  end
end

