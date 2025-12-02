# Service for generating consolidated team calendar views
#
# This service creates a unified calendar view showing all team members'
# availability, holidays, and time-off in a single consolidated display.
# Managers can see at a glance who is available and who is on leave for any given day.
class TeamCalendarService
  def initialize(team, start_date, end_date)
    @team = team
    @start_date = start_date.to_date
    @end_date = end_date.to_date
    @users = @team.users.order(:name)
  end

  # Returns consolidated calendar data for all team members
  def consolidated_calendar_data
    calendar_data = {}

    (@start_date..@end_date).each do |date|
      calendar_data[date] = {
        date: date,
        is_weekend: date.saturday? || date.sunday?,
        is_global_holiday: global_holiday_on_date?(date),
        global_holiday: get_global_holiday_for_date(date),
        members_available: [],
        members_on_holiday: [],
        members_on_time_off: [],
        members_on_global_holiday: [],
        total_members: @users.count,
        available_count: 0,
        unavailable_count: 0
      }

      @users.each do |user|
        status = get_user_status_for_date(user, date)

        case status[:type]
        when :available
          calendar_data[date][:members_available] << { user: user, status: status }
          calendar_data[date][:available_count] += 1
        when :holiday
          calendar_data[date][:members_on_holiday] << { user: user, status: status }
          calendar_data[date][:unavailable_count] += 1
        when :time_off
          calendar_data[date][:members_on_time_off] << { user: user, status: status }
          calendar_data[date][:unavailable_count] += 1
        when :global_holiday
          calendar_data[date][:members_on_global_holiday] << { user: user, status: status }
          calendar_data[date][:unavailable_count] += 1
        when :weekend
          # Don't count weekends as unavailable for working purposes
          calendar_data[date][:members_available] << { user: user, status: status }
        end
      end
    end

    calendar_data
  end

  # Returns individual calendar data for each user (for detailed view)
  def individual_calendars_data
    calendar_data = {}

    @users.each do |user|
      service = AvailabilityCalendarService.new(user, @start_date, @end_date)
      calendar_data[user.id] = {
        user: user,
        availability_data: service.availability_data,
        summary: service.summary
      }
    end

    calendar_data
  end

  # Get team members who are on leave today
  def team_members_on_leave_today
    today = Date.current
    return [] unless today.between?(@start_date, @end_date)

    on_leave = []

    @users.each do |user|
      status = get_user_status_for_date(user, today)

      if [:time_off, :holiday, :global_holiday].include?(status[:type]) && !today.weekend?
        on_leave << {
          user: user,
          status: status[:type],
          reason: status[:reason],
          details: status[:details],
          type: status[:type] # for backward compatibility
        }
      end
    end

    on_leave
  end

  # Get summary statistics for the team
  def team_summary
    total_working_days = (@start_date..@end_date).count { |d| d.wday.between?(1, 5) }
    total_member_days = total_working_days * @users.count

    unavailable_days = 0
    available_days = 0

    (@start_date..@end_date).each do |date|
      next if date.weekend?

      @users.each do |user|
        status = get_user_status_for_date(user, date)
        if [:time_off, :holiday, :global_holiday].include?(status[:type])
          unavailable_days += 1
        else
          available_days += 1
        end
      end
    end

    {
      total_members: @users.count,
      total_working_days: total_working_days,
      total_member_days: total_member_days,
      available_member_days: available_days,
      unavailable_member_days: unavailable_days,
      availability_percentage: total_member_days > 0 ? (available_days.to_f / total_member_days * 100).round(1) : 0
    }
  end

  private

  def get_user_status_for_date(user, date)
    # Priority: weekend > global holiday > personal holiday > time off > available
    if date.saturday? || date.sunday?
      return { type: :weekend, reason: "Weekend", details: "" }
    end

    if global_holiday_on_date?(date)
      holiday = get_global_holiday_for_date(date)
      return {
        type: :global_holiday,
        reason: "Global Holiday: #{holiday.name}",
        details: holiday.description || holiday.name,
        holiday: holiday
      }
    end

    if user_holiday_on_date?(user, date)
      holiday = get_user_holiday_for_date(user, date)
      return {
        type: :holiday,
        reason: "Personal Holiday: #{holiday.name}",
        details: holiday.name,
        holiday: holiday
      }
    end

    if user_time_off_on_date?(user, date)
      time_off = get_user_time_off_for_date(user, date)
      return {
        type: :time_off,
        reason: "Time Off: #{time_off.leave_type}",
        details: time_off.reason || time_off.leave_type,
        time_off: time_off
      }
    end

    { type: :available, reason: "Available", details: "" }
  end

  def global_holiday_on_date?(date)
    GlobalHoliday.exists?(date: date)
  end

  def get_global_holiday_for_date(date)
    GlobalHoliday.find_by(date: date)
  end

  def user_holiday_on_date?(user, date)
    user.holidays.exists?(date: date)
  end

  def get_user_holiday_for_date(user, date)
    user.holidays.find_by(date: date)
  end

  def user_time_off_on_date?(user, date)
    user.time_offs.where("? BETWEEN start_date AND end_date", date).exists?
  end

  def get_user_time_off_for_date(user, date)
    user.time_offs.where("? BETWEEN start_date AND end_date", date).first
  end

  # Helper method to extend Date class functionality
  def weekend?(date)
    date.saturday? || date.sunday?
  end
end

# Extend Date class to add weekend? method if not already present
class Date
  def weekend?
    saturday? || sunday?
  end
end