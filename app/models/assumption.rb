class Assumption < ApplicationRecord
  belongs_to :project
  belongs_to :scope_item, optional: true

  validates :title, presence: true
  validates :status, inclusion: { in: %w[open validated invalidated] }

  STATUSES = %w[open validated invalidated].freeze

  scope :open_assumptions, -> { where(status: "open") }
  scope :project_level, -> { where(scope_item_id: nil) }
end
