class RisksController < ApplicationController
  before_action :set_project
  before_action :set_risk, only: [:edit, :update, :destroy]

  def new
    @risk = @project.risks.build
    @risk.scope_item_id = params[:scope_item_id] if params[:scope_item_id]
  end

  def create
    @risk = @project.risks.build(risk_params)

    if @risk.save
      redirect_to scoping_project_path(@project), notice: "Risk was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @risk.update(risk_params)
      redirect_to scoping_project_path(@project), notice: "Risk was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @risk.destroy
    redirect_to scoping_project_path(@project), notice: "Risk was successfully deleted."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_risk
    @risk = @project.risks.find(params[:id])
  end

  def risk_params
    params.require(:risk).permit(:title, :description, :likelihood, :impact, :status, :mitigation_plan, :scope_item_id)
  end
end
