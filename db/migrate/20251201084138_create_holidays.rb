class CreateHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :holidays do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.string :name

      t.timestamps
    end
  end
end
