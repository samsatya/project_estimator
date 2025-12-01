class AddJiraFieldsToEpics < ActiveRecord::Migration[8.1]
  def change
    add_column :epics, :jira_epic_key, :string
    add_column :epics, :jira_epic_id, :integer
    add_column :epics, :last_synced_at, :datetime
    add_index :epics, :jira_epic_key
    add_index :epics, :jira_epic_id
  end
end
