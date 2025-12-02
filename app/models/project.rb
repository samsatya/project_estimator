class Project < ApplicationRecord
  has_many :epics, dependent: :destroy
  has_many :stories, through: :epics
  has_many :subtasks, through: :stories
  has_many :team_member_projects, dependent: :destroy
  has_many :users, through: :team_member_projects
  has_many :project_teams, dependent: :destroy
  has_many :teams, through: :project_teams

  validates :name, presence: true
  validates :pr_review_time_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_testing_time_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :business_testing_time_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :points_to_hours_conversion, presence: true, numericality: { greater_than: 0 }

  encrypts :aws_secret_access_key

  def jira_configured?
    jira_site_url.present? && jira_username.present? && jira_api_token.present? && jira_project_key.present?
  end

  def aws_configured?
    aws_access_key_id.present? && aws_secret_access_key.present? && aws_region.present?
  end

  before_validation :set_defaults

  private

  def set_defaults
    self.pr_review_time_percentage ||= 0.15 # 15%
    self.product_testing_time_percentage ||= 0.20 # 20%
    self.business_testing_time_percentage ||= 0.15 # 15%
    self.points_to_hours_conversion ||= 8.0 # 1 point = 8 hours
    self.status ||= "planning"
  end
end
