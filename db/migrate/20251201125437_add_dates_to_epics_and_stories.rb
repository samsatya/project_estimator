class AddDatesToEpicsAndStories < ActiveRecord::Migration[8.1]
  def change
    add_column :epics, :start_date, :date
    add_column :epics, :end_date, :date
    add_column :stories, :start_date, :date
    add_column :stories, :end_date, :date
  end
end
