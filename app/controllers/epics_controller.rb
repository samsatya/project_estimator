class EpicsController < ApplicationController
  before_action :set_project
  before_action :set_epic, only: [ :edit, :update, :destroy, :bulk_upload, :process_bulk_upload, :download_template, :export_to_jira, :refine_with_ai, :generate_stories ]

  def create
    @epic = @project.epics.build(epic_params)
    @epic.position = (@project.epics.maximum(:position) || 0) + 1

    if @epic.save
      redirect_to @project, notice: "Epic was successfully created."
    else
      redirect_to @project, alert: "Error creating epic: #{@epic.errors.full_messages.join(', ')}"
    end
  end

  def edit
  end

  def update
    if @epic.update(epic_params)
      redirect_to @project, notice: "Epic was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @epic.destroy
    redirect_to @project, notice: "Epic was successfully deleted."
  end

  def bulk_upload
    # Show upload form
  end

  def process_bulk_upload
    if params[:csv_file].blank?
      redirect_to bulk_upload_project_epic_path(@project, @epic), alert: "Please select a CSV file to upload."
      return
    end

    csv_content = params[:csv_file].read

    # Handle encoding issues by detecting and converting to UTF-8
    begin
      # Try to detect encoding and convert to UTF-8
      csv_content = csv_content.force_encoding("UTF-8")

      # If it's not valid UTF-8, try common encodings
      unless csv_content.valid_encoding?
        # Try Windows-1252 (common for Excel files)
        csv_content = params[:csv_file].read.force_encoding("Windows-1252").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      end
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      # Fall back to ASCII-8BIT and force conversion
      csv_content = params[:csv_file].read.force_encoding("ASCII-8BIT").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    end

    service = BulkUploadService.new(@epic)

    begin
      Rails.logger.info "Starting CSV import for epic: #{@epic.name}"
      if service.import_from_csv(csv_content)
        notice = "Bulk upload completed successfully! "
        notice += "Imported #{service.imported_count[:stories]} stories and #{service.imported_count[:subtasks]} subtasks."
        Rails.logger.info "CSV import successful: #{service.imported_count}"
        redirect_to @project, notice: notice
      else
        @errors = service.errors
        Rails.logger.error "CSV import failed with errors: #{@errors.join(', ')}"
        render :bulk_upload, status: :unprocessable_entity
      end
    rescue StandardError => e
      @errors = [ "An error occurred while processing the CSV: #{e.message}" ]
      Rails.logger.error "CSV import exception: #{e.message}\n#{e.backtrace.first(5).join('\n')}"
      render :bulk_upload, status: :unprocessable_entity
    end
  end

  def download_template
    csv_content = BulkUploadService.generate_template
    send_data csv_content,
              filename: "bulk_upload_template_#{Date.today}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  def export_to_jira
    service = JiraCsvExportService.new(@epic)
    csv_content = service.export_to_csv

    filename = "jira_import_#{@epic.name.parameterize}_#{Date.today.strftime('%Y%m%d')}.csv"

    send_data csv_content,
              filename: filename,
              type: "text/csv",
              disposition: "attachment"
  end

  # AI-powered epic refinement
  def refine_with_ai
    ai_service = EpicAiService.new(@epic)
    result = ai_service.refine

    if result[:success]
      render json: {
        success: true,
        refined_name: result[:refined_name],
        refined_description: result[:refined_description],
        suggestions: result[:suggestions]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # AI-powered story generation from epic
  def generate_stories
    ai_service = EpicAiService.new(@epic)
    result = ai_service.generate_stories

    if result[:success]
      render json: {
        success: true,
        stories: result[:stories]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Project not found."
  end

  def set_epic
    Rails.logger.info "Attempting to find epic with ID: #{params[:id]} for project: #{@project&.id}"
    @epic = @project.epics.find(params[:id])
    Rails.logger.info "Successfully found epic: #{@epic.name}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Epic not found: #{e.message}. Project: #{@project&.id}, Epic ID: #{params[:id]}"
    redirect_to @project, alert: "Epic not found (ID: #{params[:id]})."
  end

      def epic_params
        params.require(:epic).permit(:name, :description, :position, :start_date, :end_date)
      end
end
