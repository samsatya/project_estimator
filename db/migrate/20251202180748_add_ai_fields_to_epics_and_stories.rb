class AddAiFieldsToEpicsAndStories < ActiveRecord::Migration[8.1]
  def change
    # Add AI tracking fields to epics
    add_column :epics, :ai_generated, :boolean, default: false
    add_column :epics, :ai_refined_at, :datetime
    add_column :epics, :original_description, :text

    # Add AI tracking fields to stories
    add_column :stories, :ai_generated, :boolean, default: false
    add_column :stories, :ai_refined_at, :datetime
    add_column :stories, :original_description, :text
    add_column :stories, :ai_suggested_points, :integer
  end
end
