class CreateProjectTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :project_teams do |t|
      t.references :project, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end

    add_index :project_teams, [:project_id, :team_id], unique: true
  end
end
