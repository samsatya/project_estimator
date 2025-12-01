class AvailabilityCalendarService
  def initialize(user, start_date, end_date)
    @user = user
    @start_date = start_date.to_date
    @end_date = end_date.to_date
  end

  def availability_data
    calendar = {}
    (@start_date..@end_date).each do |date|
      calendar[date] = {
        date: date,
        is_weekend: date.saturday? || date.sunday?,
        is_holiday: holiday_on_date?(date),
        time_off: time_off_on_date?(date),
        status: get_status(date)
      }
    end
    calendar
  end

  def get_status(date)
    return :weekend if date.saturday? || date.sunday?
    return :global_holiday if global_holiday_on_date?(date)
    return :holiday if holiday_on_date?(date)
    return :time_off if time_off_on_date?(date)
    :available
  end

  def global_holiday_on_date?(date)
    GlobalHoliday.exists?(date: date)
  end

  def holiday_on_date?(date)
    @user.holidays.exists?(date: date)
  end

  def time_off_on_date?(date)
    @user.time_offs.where("? BETWEEN start_date AND end_date", date).exists?
  end

  def get_time_off_for_date(date)
    @user.time_offs.where("? BETWEEN start_date AND end_date", date).first
  end

  def get_global_holiday_for_date(date)
    GlobalHoliday.find_by(date: date)
  end

  def get_holiday_for_date(date)
    @user.holidays.find_by(date: date)
  end

  def summary
    total_days = (@end_date - @start_date).to_i + 1
    working_days = (@start_date..@end_date).count { |d| d.wday.between?(1, 5) }
    global_holiday_days = (@start_date..@end_date).count { |d| !d.saturday? && !d.sunday? && global_holiday_on_date?(d) }
    user_holiday_days = (@start_date..@end_date).count { |d| !d.saturday? && !d.sunday? && holiday_on_date?(d) && !global_holiday_on_date?(d) }
    holiday_days = global_holiday_days + user_holiday_days
    time_off_days = (@start_date..@end_date).count { |d| !d.saturday? && !d.sunday? && time_off_on_date?(d) }
    available_days = working_days - holiday_days - time_off_days

    {
      total_days: total_days,
      working_days: working_days,
      global_holiday_days: global_holiday_days,
      user_holiday_days: user_holiday_days,
      holiday_days: holiday_days,
      time_off_days: time_off_days,
      available_days: available_days,
      unavailable_days: holiday_days + time_off_days
    }
  end
end

