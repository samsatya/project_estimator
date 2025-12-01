class AddJiraFieldsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :jira_project_key, :string
    add_column :projects, :jira_site_url, :string
    add_column :projects, :jira_username, :string
    add_column :projects, :jira_api_token, :string
    add_column :projects, :sync_enabled, :boolean, default: false
    add_index :projects, :jira_project_key
  end
end
