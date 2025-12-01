class CreateTeamMemberProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :team_member_projects do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :role

      t.timestamps
    end
  end
end
