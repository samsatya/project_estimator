class GlobalHolidaysController < ApplicationController
  before_action :ensure_manager
  before_action :set_global_holiday, only: [:edit, :update, :destroy]

  def index
    @year = params[:year]&.to_i || Date.current.year
    @global_holidays = GlobalHoliday.by_year(@year).order(:date)
  end

  def new
    @global_holiday = GlobalHoliday.new
  end

  def create
    @global_holiday = GlobalHoliday.new(global_holiday_params)

    if @global_holiday.save
      redirect_to global_holidays_path, notice: "Global holiday was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @global_holiday.update(global_holiday_params)
      redirect_to global_holidays_path, notice: "Global holiday was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @global_holiday.destroy
    redirect_to global_holidays_path, notice: "Global holiday was successfully deleted."
  end

  def bulk_upload
    # Show upload form
  end

  def process_bulk_upload
    if params[:csv_file].blank?
      redirect_to bulk_upload_global_holidays_path, alert: "Please select a CSV file to upload."
      return
    end

    begin
      # Read file content and handle encoding
      csv_content = params[:csv_file].read
      csv_content.force_encoding('UTF-8') if csv_content.respond_to?(:force_encoding)
      
      service = GlobalHolidayBulkUploadService.new
      
      if service.import_from_csv(csv_content)
        notice = "Bulk upload completed successfully! Imported #{service.imported_count} global holidays."
        redirect_to global_holidays_path, notice: notice
      else
        @errors = service.errors
        render :bulk_upload, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Bulk upload error: #{e.message}\n#{e.backtrace.join("\n")}"
      @errors = ["Error processing file: #{e.message}"]
      render :bulk_upload, status: :unprocessable_entity
    end
  end

  def download_template
    csv_content = GlobalHolidayBulkUploadService.generate_template
    send_data csv_content, 
              filename: "global_holidays_template_#{Date.today}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def ensure_manager
    unless current_user&.manager?
      redirect_to root_path, alert: "You must be a manager to access this page."
    end
  end

  def set_global_holiday
    @global_holiday = GlobalHoliday.find(params[:id])
  end

  def global_holiday_params
    params.require(:global_holiday).permit(:date, :name, :description)
  end
end
