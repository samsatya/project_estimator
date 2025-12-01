class CreateStories < ActiveRecord::Migration[8.0]
  def change
    create_table :stories do |t|
      t.references :epic, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :points
      t.references :assigned_user, null: true, foreign_key: { to_table: :users }
      t.string :status
      t.decimal :estimated_hours, precision: 10, scale: 2

      t.timestamps
    end
  end
end
