class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :dashboard, :add_team_member, :remove_team_member, :add_team, :remove_team, :export, :gantt_chart, :pivot_report, :jira_config, :update_jira_config, :test_jira_connection, :sync_to_jira, :sync_from_jira, :scoping, :complete_scoping, :reopen_scoping]

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

  def jira_config
    begin
      @jira_service = JiraService.new(@project)
    rescue LoadError => e
      flash.now[:alert] = "Jira gem not loaded. Please restart your Rails server: #{e.message}"
      @jira_service = nil
    rescue StandardError => e
      flash.now[:alert] = "Error initializing Jira service: #{e.message}"
      @jira_service = nil
    end
  end

  def update_jira_config
    if @project.update(jira_config_params)
      redirect_to jira_config_project_path(@project), notice: "Jira configuration updated successfully."
    else
      @jira_service = JiraService.new(@project)
      render :jira_config, status: :unprocessable_entity
    end
  end

  def test_jira_connection
    @project.assign_attributes(jira_config_params)
    jira_service = JiraService.new(@project)
    result = jira_service.test_connection

    if result[:success]
      render json: { success: true, message: "Connection successful! Project: #{result[:project_name]}" }
    else
      render json: { success: false, message: result[:error] }, status: :unprocessable_entity
    end
  end

  def sync_to_jira
    jira_service = JiraService.new(@project)
    result = jira_service.sync_to_jira

    if result[:success]
      notice = "Sync completed! Exported #{result[:synced_count][:epics]} epics and #{result[:synced_count][:stories]} stories to Jira."
      redirect_to @project, notice: notice
    else
      error_msg = "Sync failed. "
      error_msg += result[:error] if result[:error]
      error_msg += " Errors: #{result[:errors].join('; ')}" if result[:errors]&.any?
      redirect_to @project, alert: error_msg
    end
  end

  def sync_from_jira
    jira_service = JiraService.new(@project)
    result = jira_service.sync_from_jira

    if result[:success]
      notice = "Sync completed! Imported #{result[:synced_count][:epics]} epics and #{result[:synced_count][:stories]} stories from Jira."
      notice += " Errors: #{result[:errors].join('; ')}" if result[:errors]&.any?
      redirect_to @project, notice: notice
    else
      redirect_to @project, alert: "Sync failed: #{result[:error]}"
    end
  end

  def gantt_chart
    @epics = @project.epics.ordered.includes(:stories)
    # Calculate dates if not set
    @epics.each do |epic|
      if epic.start_date.nil? || epic.end_date.nil?
        story_dates = epic.stories.where.not(start_date: nil, end_date: nil)
        if story_dates.any?
          epic.start_date ||= story_dates.minimum(:start_date)
          epic.end_date ||= story_dates.maximum(:end_date)
        end
      end
    end
  end

  def pivot_report
    @stories = @project.stories.includes(:epic, :assigned_user)
    @epics = @project.epics.ordered
    @users = @project.users
  end

  def scoping
    @scope_items = @project.scope_items.ordered.includes(:assumptions, :risks, :converted_to_epic)
    @project_assumptions = @project.assumptions.project_level
    @project_risks = @project.risks.where(scope_item_id: nil)
    @scoping_calculator = ScopingCalculator.new(@project)
  end

  def complete_scoping
    if @project.can_advance_to_estimation?
      if @project.advance_to_estimation!
        redirect_to @project, notice: "Scoping phase completed. You can now create detailed estimates."
      else
        redirect_to scoping_project_path(@project), alert: "Failed to complete scoping phase."
      end
    else
      redirect_to scoping_project_path(@project), alert: "Cannot complete scoping. Ensure you have approved scope items and no open assumptions."
    end
  end

  def reopen_scoping
    if @project.update(phase: "scoping", scoping_completed_at: nil)
      redirect_to scoping_project_path(@project), notice: "Scoping phase reopened."
    else
      redirect_to @project, alert: "Failed to reopen scoping phase."
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

  def jira_config_params
    params.require(:project).permit(:jira_site_url, :jira_username, :jira_api_token, :jira_project_key, :sync_enabled)
  end
end
