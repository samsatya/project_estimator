class AddUniqueIndexToGlobalHolidaysDate < ActiveRecord::Migration[8.1]
  def change
    add_index :global_holidays, :date, unique: true, if_not_exists: true
  end
end
