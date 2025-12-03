class CreateAssumptions < ActiveRecord::Migration[8.1]
  def change
    create_table :assumptions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :scope_item, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, default: "open"
      t.text :validation_notes
      t.timestamps
    end
  end
end
