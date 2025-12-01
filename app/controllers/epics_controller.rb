class EpicsController < ApplicationController
  before_action :set_project
  before_action :set_epic, only: [:edit, :update, :destroy, :bulk_upload, :process_bulk_upload, :download_template]

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
    service = BulkUploadService.new(@epic)
    
    if service.import_from_csv(csv_content)
      notice = "Bulk upload completed successfully! "
      notice += "Imported #{service.imported_count[:stories]} stories and #{service.imported_count[:subtasks]} subtasks."
      redirect_to @project, notice: notice
    else
      @errors = service.errors
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

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_epic
    @epic = @project.epics.find(params[:id])
  end

  def epic_params
    params.require(:epic).permit(:name, :description, :position)
  end
end
