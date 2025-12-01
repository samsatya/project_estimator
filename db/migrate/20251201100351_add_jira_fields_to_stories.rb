class AddJiraFieldsToStories < ActiveRecord::Migration[8.1]
  def change
    add_column :stories, :jira_issue_key, :string
    add_column :stories, :jira_issue_id, :integer
    add_column :stories, :last_synced_at, :datetime
    add_index :stories, :jira_issue_key
    add_index :stories, :jira_issue_id
  end
end
