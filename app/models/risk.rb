class Risk < ApplicationRecord
  belongs_to :project
  belongs_to :scope_item, optional: true

  validates :title, presence: true
  validates :likelihood, inclusion: { in: %w[low medium high] }, allow_nil: true
  validates :impact, inclusion: { in: %w[low medium high] }, allow_nil: true
  validates :status, inclusion: { in: %w[identified mitigating mitigated accepted] }

  LIKELIHOODS = %w[low medium high].freeze
  IMPACTS = %w[low medium high].freeze
  STATUSES = %w[identified mitigating mitigated accepted].freeze

  scope :active, -> { where.not(status: "mitigated") }
  scope :high_priority, -> { where(likelihood: "high").or(where(impact: "high")) }
end
