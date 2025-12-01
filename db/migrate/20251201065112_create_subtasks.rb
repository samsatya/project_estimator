class CreateSubtasks < ActiveRecord::Migration[8.0]
  def change
    create_table :subtasks do |t|
      t.references :story, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.references :assigned_user, null: true, foreign_key: { to_table: :users }
      t.decimal :estimated_hours, precision: 10, scale: 2
      t.string :status

      t.timestamps
    end
  end
end
