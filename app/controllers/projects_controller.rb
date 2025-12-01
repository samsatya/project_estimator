class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :dashboard, :add_team_member, :remove_team_member, :add_team, :remove_team, :export]

  def index
    @projects = Project.all.order(created_at: :desc)
  end

  def show
    @epics = @project.epics.ordered.includes(:stories)
    @calculator = EstimationCalculator.new(@project)
    @available_users = User.where.not(id: @project.user_ids)
    @available_teams = Team.where.not(id: @project.team_ids)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  def dashboard
    @calculator = EstimationCalculator.new(@project)
    @breakdown = @calculator.breakdown
    @by_epic = @calculator.by_epic
    @by_team_member = @calculator.by_team_member
  end

  def add_team_member
    user = User.find(params[:user_id])
    unless @project.users.include?(user)
      @project.users << user
      redirect_to @project, notice: "#{user.name} added to project."
    else
      redirect_to @project, alert: "User is already in the project."
    end
  end

  def remove_team_member
    user = User.find(params[:user_id])
    @project.users.delete(user)
    redirect_to @project, notice: "#{user.name} removed from project."
  end

  def add_team
    team = Team.find(params[:team_id])
    unless @project.teams.include?(team)
      @project.teams << team
      redirect_to @project, notice: "#{team.name} team added to project."
    else
      redirect_to @project, alert: "Team is already in the project."
    end
  end

  def remove_team
    team = Team.find(params[:team_id])
    @project.teams.delete(team)
    redirect_to @project, notice: "#{team.name} team removed from project."
  end

  def export
    @calculator = EstimationCalculator.new(@project)
    @breakdown = @calculator.breakdown
    @by_epic = @calculator.by_epic
    @by_team_member = @calculator.by_team_member
    @epics = @project.epics.ordered.includes(:stories, :project)
    
    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@project.name.parameterize}_estimation_#{Date.today}.xlsx\""
      }
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :start_date, :target_date, :status,
                                    :pr_review_time_percentage, :product_testing_time_percentage,
                                    :business_testing_time_percentage, :points_to_hours_conversion)
  end
end
