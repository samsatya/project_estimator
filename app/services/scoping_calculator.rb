class ScopingCalculator
  def initialize(project)
    @project = project
  end

  def total_rough_hours
    @project.scope_items.approved.sum { |item| item.rough_hours || 0 }
  end

  def hours_by_size
    ScopeItem::TSHIRT_SIZES.map do |size|
      items = @project.scope_items.approved.where(tshirt_size: size)
      {
        size: size,
        count: items.count,
        hours: items.sum { |item| item.rough_hours || 0 }
      }
    end
  end

  def hours_by_category
    ScopeItem::CATEGORIES.map do |category|
      items = @project.scope_items.approved.where(category: category)
      {
        category: category,
        count: items.count,
        hours: items.sum { |item| item.rough_hours || 0 }
      }
    end.select { |c| c[:count] > 0 }
  end

  def rough_weeks(hours_per_week: 40)
    return 0 if total_rough_hours.zero?
    (total_rough_hours.to_f / hours_per_week).ceil
  end

  def completion_status
    {
      total_scope_items: @project.scope_items.count,
      approved: @project.scope_items.approved.count,
      converted: @project.scope_items.where.not(converted_to_epic_id: nil).count,
      open_assumptions: @project.assumptions.open_assumptions.count,
      active_risks: @project.risks.active.count,
      high_risks: @project.risks.high_priority.count
    }
  end

  def ready_to_complete?
    @project.scope_items.approved.any? && @project.assumptions.open_assumptions.none?
  end
end
