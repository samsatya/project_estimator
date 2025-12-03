class ScopeItemsController < ApplicationController
  before_action :set_project
  before_action :set_scope_item, only: [:edit, :update, :destroy, :convert_to_epic]
  before_action :ensure_scoping_phase, except: [:convert_to_epic]

  def new
    @scope_item = @project.scope_items.build
  end

  def create
    @scope_item = @project.scope_items.build(scope_item_params)
    @scope_item.position = (@project.scope_items.maximum(:position) || 0) + 1

    if @scope_item.save
      redirect_to scoping_project_path(@project), notice: "Scope item was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @scope_item.update(scope_item_params)
      redirect_to scoping_project_path(@project), notice: "Scope item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scope_item.destroy
    redirect_to scoping_project_path(@project), notice: "Scope item was successfully deleted."
  end

  def convert_to_epic
    service = ScopeToEpicConverter.new(@scope_item)

    if service.convert!
      redirect_to @project, notice: "Scope item converted to epic: #{service.epic.name}"
    else
      redirect_to scoping_project_path(@project), alert: "Failed to convert: #{service.errors.join(', ')}"
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_scope_item
    @scope_item = @project.scope_items.find(params[:id])
  end

  def ensure_scoping_phase
    unless @project.in_scoping_phase?
      redirect_to @project, alert: "Scoping phase is complete. Cannot modify scope items."
    end
  end

  def scope_item_params
    params.require(:scope_item).permit(:name, :description, :tshirt_size, :category, :priority, :status)
  end
end
