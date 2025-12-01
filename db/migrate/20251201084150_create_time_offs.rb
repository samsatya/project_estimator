class CreateTimeOffs < ActiveRecord::Migration[8.1]
  def change
    create_table :time_offs do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :leave_type
      t.text :reason

      t.timestamps
    end
  end
end
