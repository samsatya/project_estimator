module ApplicationHelper
  # Helper method for calendar cell styling (used in availability calendar)
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

  # Helper method for team calendar cell styling
  def team_calendar_cell_class(day_data)
    return "cell-weekend" if day_data[:is_weekend]
    return "cell-global-holiday" if day_data[:is_global_holiday]

    if day_data[:available_count] == day_data[:total_members]
      "cell-all-available"
    elsif day_data[:available_count] > day_data[:unavailable_count]
      "cell-mostly-available"
    elsif day_data[:unavailable_count] >= day_data[:available_count]
      "cell-mostly-unavailable"
    else
      "cell-mixed"
    end
  end
end
