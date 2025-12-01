module AvailabilityCalendarHelper
  def cell_class(status)
    case status
    when :available
      "cell-available"
    when :global_holiday
      "cell-global-holiday"
    when :holiday
      "cell-holiday"
    when :time_off
      "cell-time_off"
    when :weekend
      "cell-weekend"
    else
      ""
    end
  end
end
