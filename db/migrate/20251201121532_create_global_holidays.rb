class CreateGlobalHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :global_holidays do |t|
      t.date :date
      t.string :name
      t.text :description

      t.timestamps
    end
    
    add_index :global_holidays, :date, unique: true
  end
end
