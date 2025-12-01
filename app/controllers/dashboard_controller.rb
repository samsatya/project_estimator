class DashboardController < ApplicationController
  def show
    @project = Project.find(params[:project_id])
    @calculator = EstimationCalculator.new(@project)
    @breakdown = @calculator.breakdown
    @by_epic = @calculator.by_epic
    @by_team_member = @calculator.by_team_member
  end
end
