class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :assigned_stories, class_name: "Story", foreign_key: "assigned_user_id", dependent: :nullify
  has_many :assigned_subtasks, class_name: "Subtask", foreign_key: "assigned_user_id", dependent: :nullify
  has_many :team_member_projects, dependent: :destroy
  has_many :projects, through: :team_member_projects
  has_many :team_members, dependent: :destroy
  has_many :teams, through: :team_members
  has_many :holidays, dependent: :destroy
  has_many :time_offs, dependent: :destroy

  validates :name, presence: true
  validates :primary_strength, presence: true
  validates :secondary_strength, presence: true
  validates :role, inclusion: { in: %w[team_member manager team_member_manager] }

  ROLES = {
    team_member: "team_member",
    manager: "manager",
    team_member_manager: "team_member_manager"
  }.freeze

  def team_member?
    role == "team_member" || role == "team_member_manager"
  end

  def manager?
    role == "manager" || role == "team_member_manager"
  end

  def manager_or_team_member_manager?
    manager? || role == "team_member_manager"
  end
end
