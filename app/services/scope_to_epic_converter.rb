class ScopeToEpicConverter
  attr_reader :scope_item, :epic, :errors

  def initialize(scope_item)
    @scope_item = scope_item
    @project = scope_item.project
    @errors = []
    @epic = nil
  end

  def convert!
    return add_error("Scope item must be approved before converting") unless scope_item.status == "approved"
    return add_error("Scope item already converted") if scope_item.converted?

    ActiveRecord::Base.transaction do
      create_epic
      update_scope_item
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  private

  def create_epic
    @epic = @project.epics.create!(
      name: scope_item.name,
      description: build_epic_description,
      position: (@project.epics.maximum(:position) || 0) + 1
    )
  end

  def update_scope_item
    scope_item.update!(
      status: "converted",
      converted_to_epic_id: @epic.id
    )
  end

  def build_epic_description
    parts = []
    parts << scope_item.description if scope_item.description.present?
    parts << "\n\n---\nConverted from scope item"
    parts << "T-shirt size: #{scope_item.tshirt_size}" if scope_item.tshirt_size
    parts << "Category: #{scope_item.category}" if scope_item.category
    parts << "Priority: #{scope_item.priority}" if scope_item.priority
    parts.join("\n")
  end

  def add_error(message)
    @errors << message
    false
  end
end
