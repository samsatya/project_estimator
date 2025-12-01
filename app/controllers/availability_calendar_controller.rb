class AvailabilityCalendarController < ApplicationController
  before_action :set_team_or_user
  before_action :ensure_authorized

  def index
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_month
    
    # Set users based on what was determined in set_team_or_user
    unless @users
      if @team
        @users = @team.users.order(:name)
        @view_type = "team"
      elsif @user
        @users = [@user]
        @view_type = "user"
      elsif @view_all
        @users = User.all.order(:name)
        @view_type = "all"
      else
        # Fallback: show current user
        @users = [current_user]
        @view_type = "user"
      end
    end

    @calendar_data = {}
    @summaries = {}
    @holidays_by_user = {}
    @time_offs_by_user = {}
    @global_holidays = GlobalHoliday.where(date: @start_date..@end_date).index_by(&:date)
    
    @users.each do |user|
      # Preload holidays and time offs for efficiency
      @holidays_by_user[user.id] = user.holidays.where(date: @start_date..@end_date).index_by(&:date)
      @time_offs_by_user[user.id] = user.time_offs.in_period(@start_date, @end_date).to_a
      
      service = AvailabilityCalendarService.new(user, @start_date, @end_date)
      @calendar_data[user.id] = service.availability_data
      @summaries[user.id] = service.summary
    end

    # Get team members on leave today
    @today = Date.current
    @team_members_on_leave_today = get_team_members_on_leave_today
  end

  private

  def set_team_or_user
    if params[:team_id].present?
      @team = Team.find(params[:team_id])
      @user = nil
    elsif params[:user_id].present?
      @user = User.find(params[:user_id])
      @team = nil
    else
      # Default: show current user's teams or all teams if manager
      if current_user.manager?
        @team = nil
        @user = nil
        @view_all = true
      else
        # Show user's first team or user themselves
        @team = current_user.teams.first
        @user = @team ? nil : current_user
      end
    end
  end

  def ensure_authorized
    if @team
      # User must be a member of the team or a manager
      unless current_user.teams.include?(@team) || current_user.manager?
        redirect_to root_path, alert: "You are not authorized to view this team's calendar."
      end
    elsif @user
      # User must be viewing themselves, be in the same team, or be a manager
      if @user != current_user
        shared_teams = current_user.teams & @user.teams
        unless shared_teams.any? || current_user.manager?
          redirect_to root_path, alert: "You are not authorized to view this user's calendar."
        end
      end
    elsif @view_all
      # Only managers can view all
      unless current_user.manager?
        redirect_to root_path, alert: "You are not authorized to view all calendars."
      end
    end
  end

  def get_team_members_on_leave_today
    today = Date.current
    on_leave = []

    # Get users from the current view context - prioritize team members
    users_to_check = if @team
      # If viewing a specific team, show that team's members
      @team.users
    elsif @user
      # If viewing a specific user, check their teams
      @user.teams.flat_map(&:users).uniq
    elsif @view_all
      # If viewing all, check all users
      User.all
    else
      # Default: check current user's teams (for team members)
      if current_user.teams.any?
        current_user.teams.flat_map(&:users).uniq
      else
        # If user has no teams, just show themselves
        [current_user]
      end
    end

    users_to_check.each do |user|
      # Check if user has time off today
      has_time_off = user.time_offs.where("? BETWEEN start_date AND end_date", today).exists?
      
      # Check if today is a global holiday (not a weekend)
      is_global_holiday = GlobalHoliday.exists?(date: today) && !today.saturday? && !today.sunday?
      
      # Check if user has a personal holiday today
      has_personal_holiday = user.holidays.exists?(date: today)
      
      # Check if today is a weekend
      is_weekend = today.saturday? || today.sunday?

      if has_time_off
        time_off = user.time_offs.where("? BETWEEN start_date AND end_date", today).first
        on_leave << {
          user: user,
          reason: "Time Off: #{time_off.leave_type}",
          details: time_off.reason,
          type: :time_off
        }
      elsif has_personal_holiday
        holiday = user.holidays.find_by(date: today)
        on_leave << {
          user: user,
          reason: "Personal Holiday: #{holiday.name}",
          details: holiday.name,
          type: :holiday
        }
      elsif is_global_holiday && !is_weekend
        global_holiday = GlobalHoliday.find_by(date: today)
        on_leave << {
          user: user,
          reason: "Global Holiday: #{global_holiday.name}",
          details: global_holiday.description,
          type: :global_holiday
        }
      elsif is_weekend
        # Don't show weekends as "on leave" - they're just not working days
      end
    end

    on_leave
  end
end
