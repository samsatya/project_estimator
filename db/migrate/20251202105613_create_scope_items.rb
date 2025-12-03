class CreateScopeItems < ActiveRecord::Migration[8.1]
  def change
    create_table :scope_items do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :tshirt_size
      t.string :category
      t.string :priority
      t.string :status, default: "draft"
      t.integer :position
      t.references :converted_to_epic, foreign_key: { to_table: :epics }
      t.timestamps
    end

    add_index :scope_items, [:project_id, :position]
  end
end
