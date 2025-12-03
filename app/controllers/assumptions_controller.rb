class AssumptionsController < ApplicationController
  before_action :set_project
  before_action :set_assumption, only: [:edit, :update, :destroy]

  def new
    @assumption = @project.assumptions.build
    @assumption.scope_item_id = params[:scope_item_id] if params[:scope_item_id]
  end

  def create
    @assumption = @project.assumptions.build(assumption_params)

    if @assumption.save
      redirect_to scoping_project_path(@project), notice: "Assumption was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assumption.update(assumption_params)
      redirect_to scoping_project_path(@project), notice: "Assumption was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assumption.destroy
    redirect_to scoping_project_path(@project), notice: "Assumption was successfully deleted."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_assumption
    @assumption = @project.assumptions.find(params[:id])
  end

  def assumption_params
    params.require(:assumption).permit(:title, :description, :status, :validation_notes, :scope_item_id)
  end
end
