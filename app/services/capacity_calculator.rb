class CapacityCalculator
  def initialize(user, start_date, end_date)
    @user = user
    @start_date = start_date.to_date
    @end_date = end_date.to_date
  end

  def working_days_count
    (@start_date..@end_date).count { |date| date.wday.between?(1, 5) } # Monday to Friday
  end

  def global_holiday_days_count
    # Count global holidays on working days
    GlobalHoliday.where(date: @start_date..@end_date).count { |gh| gh.date.wday.between?(1, 5) }
  end

  def available_days
    working_days = working_days_count
    holiday_days = holiday_days_count
    time_off_days = time_off_days_count
    
    working_days - holiday_days - time_off_days
  end

  def available_hours
    available_days * (@user.capacity || 40) / 5.0 # Assuming 5 working days per week
  end

  def available_story_points(conversion_rate: 8.0)
    (available_hours / conversion_rate).round(2)
  end

  def holiday_days_count
    # Count user-specific holidays
    user_holidays = @user.holidays.where(date: @start_date..@end_date).count { |holiday| holiday.date.wday.between?(1, 5) }
    
    # Count global holidays (that don't overlap with user holidays)
    global_holidays = GlobalHoliday.where(date: @start_date..@end_date)
    global_holiday_days = global_holidays.count do |gh|
      is_working_day = gh.date.wday.between?(1, 5)
      not_user_holiday = !@user.holidays.exists?(date: gh.date)
      is_working_day && not_user_holiday
    end
    
    user_holidays + global_holiday_days
  end

  def time_off_days_count
    total_days = 0
    @user.time_offs.in_period(@start_date, @end_date).each do |time_off|
      overlap_start = [time_off.start_date, @start_date].max
      overlap_end = [time_off.end_date, @end_date].min
      # Count only working days in the overlap
      overlap_days = (overlap_start..overlap_end).count { |date| date.wday.between?(1, 5) }
      total_days += overlap_days
    end
    total_days
  end

  def breakdown
    total_calendar_days = (@end_date - @start_date).to_i + 1
    working_days = working_days_count
    global_holiday_days = global_holiday_days_count
    user_holiday_days = @user.holidays.where(date: @start_date..@end_date).count { |h| h.date.wday.between?(1, 5) }
    holiday_days = holiday_days_count
    time_off_days = time_off_days_count
    available_days = working_days - holiday_days - time_off_days
    weekly_capacity = @user.capacity || 40
    available_hours = available_days * weekly_capacity / 5.0

    {
      period_start: @start_date,
      period_end: @end_date,
      total_calendar_days: total_calendar_days,
      working_days: working_days,
      global_holiday_days: global_holiday_days,
      user_holiday_days: user_holiday_days,
      holiday_days: holiday_days,
      time_off_days: time_off_days,
      available_days: available_days,
      weekly_capacity: weekly_capacity,
      available_hours: available_hours.round(2),
      available_story_points: (available_hours / 8.0).round(2)
    }
  end
end

