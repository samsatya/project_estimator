class Project < ApplicationRecord
  has_many :epics, dependent: :destroy
  has_many :stories, through: :epics
  has_many :subtasks, through: :stories
  has_many :team_member_projects, dependent: :destroy
  has_many :users, through: :team_member_projects
  has_many :project_teams, dependent: :destroy
  has_many :teams, through: :project_teams
  has_many :scope_items, dependent: :destroy
  has_many :assumptions, dependent: :destroy
  has_many :risks, dependent: :destroy

  PHASES = %w[scoping estimation execution].freeze

  validates :name, presence: true
  validates :phase, inclusion: { in: PHASES }
  validates :pr_review_time_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_testing_time_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :business_testing_time_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :points_to_hours_conversion, presence: true, numericality: { greater_than: 0 }

  def jira_configured?
    jira_site_url.present? && jira_username.present? && jira_api_token.present? && jira_project_key.present?
  end

  before_validation :set_defaults

  # Phase gate checks
  def in_scoping_phase?
    phase == "scoping"
  end

  def in_estimation_phase?
    phase == "estimation"
  end

  def can_create_stories?
    !in_scoping_phase?
  end

  def scoping_complete?
    scope_items.approved.any? && assumptions.open_assumptions.none?
  end

  def can_advance_to_estimation?
    in_scoping_phase? && scoping_complete?
  end

  def advance_to_estimation!
    return false unless can_advance_to_estimation?
    update!(phase: "estimation", scoping_completed_at: Time.current)
  end

  def rough_total_hours
    scope_items.sum { |item| item.rough_hours || 0 }
  end

  private

  def set_defaults
    self.pr_review_time_percentage ||= 0.15 # 15%
    self.product_testing_time_percentage ||= 0.20 # 20%
    self.business_testing_time_percentage ||= 0.15 # 15%
    self.points_to_hours_conversion ||= 8.0 # 1 point = 8 hours
    self.status ||= "planning"
    self.phase ||= "scoping"
  end
end
