class GlobalHolidayBulkUploadService
  attr_reader :errors, :imported_count

  def initialize
    @errors = []
    @imported_count = 0
  end

  def import_from_csv(csv_content)
    begin
      csv = CSV.parse(csv_content, headers: true, header_converters: :symbol)
      
      if csv.headers.empty?
        @errors << "CSV file is empty or invalid"
        return false
      end

      # Validate required headers
      required_headers = [:date, :name]
      missing_headers = required_headers - csv.headers
      
      if missing_headers.any?
        @errors << "Missing required columns: #{missing_headers.join(', ')}"
        return false
      end

      csv.each_with_index do |row, index|
        row_number = index + 2 # +2 because CSV is 1-indexed and we skip header
        
        date_str = row[:date]&.to_s&.strip
        name = row[:name]&.to_s&.strip
        description = row[:description]&.to_s&.strip

        if date_str.blank?
          @errors << "Row #{row_number}: Date cannot be blank"
          next
        end

        if name.blank?
          @errors << "Row #{row_number}: Name cannot be blank"
          next
        end

        begin
          date = Date.parse(date_str)
        rescue ArgumentError
          @errors << "Row #{row_number}: Invalid date format '#{date_str}'. Use YYYY-MM-DD format."
          next
        end

        # Create or update global holiday
        global_holiday = GlobalHoliday.find_or_initialize_by(date: date)
        global_holiday.name = name
        global_holiday.description = description if description.present?

        is_new_record = global_holiday.new_record?

        unless global_holiday.save
          @errors << "Row #{row_number}: #{global_holiday.errors.full_messages.join(', ')}"
          next
        end

        @imported_count += 1 if is_new_record
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
      csv << ["Date", "Name", "Description"]
      
      # Example rows
      csv << ["2024-12-25", "Christmas", "Christmas Day"]
      csv << ["2025-01-01", "New Year's Day", "New Year's Day"]
      csv << ["2025-07-04", "Independence Day", "US Independence Day"]
      csv << ["2025-12-25", "Christmas", "Christmas Day"]
    end
  end
end

