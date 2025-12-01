class AddTaskTypeToStoriesAndSubtasks < ActiveRecord::Migration[8.1]
  def change
    add_column :stories, :task_type, :string
    add_column :subtasks, :task_type, :string
  end
end
