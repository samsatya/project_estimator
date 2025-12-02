class AddAwsCredentialsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :aws_access_key_id, :string
    add_column :projects, :aws_secret_access_key, :string
    add_column :projects, :aws_region, :string, default: "us-east-1"
    add_column :projects, :aws_model_id, :string, default: "us.anthropic.claude-sonnet-4-20250514-v1:0"
  end
end
