class Team < ApplicationRecord
  has_many :team_members, dependent: :destroy
  has_many :users, through: :team_members
  has_many :project_teams, dependent: :destroy
  has_many :projects, through: :project_teams

  validates :name, presence: true
end
