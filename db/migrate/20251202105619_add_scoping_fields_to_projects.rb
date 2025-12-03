class AddScopingFieldsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :phase, :string, default: "scoping"
    add_column :projects, :scoping_completed_at, :datetime
    add_column :projects, :scoping_notes, :text
  end
end
