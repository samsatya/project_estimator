class TeamCalendarController < ApplicationController
  before_action :set_team
  before_action :ensure_manager_access

  def index
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_month

    # Initialize the team calendar service
    @service = TeamCalendarService.new(@team, @start_date, @end_date)

    # Get consolidated calendar data
    @calendar_data = @service.consolidated_calendar_data
    @team_summary = @service.team_summary
    @team_members_on_leave_today = @service.team_members_on_leave_today

    # Get individual calendar data for detailed view (optional)
    @individual_calendars = @service.individual_calendars_data if params[:detailed] == 'true'

    # Prepare data for the view
    @users = @team.users.order(:name)
    @today = Date.current
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Team not found."
  end

  def ensure_manager_access
    unless current_user.manager? || current_user.team_member_manager?
      # Check if user is a member of this specific team (team members can view their own team)
      unless current_user.teams.include?(@team)
        redirect_to root_path, alert: "You are not authorized to view this team's calendar."
      end
    end
  end
end