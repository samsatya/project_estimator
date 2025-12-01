class ProjectTeam < ApplicationRecord
  belongs_to :project
  belongs_to :team

  validates :team_id, uniqueness: { scope: :project_id }
end
