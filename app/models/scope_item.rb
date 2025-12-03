class ScopeItem < ApplicationRecord
  belongs_to :project
  belongs_to :converted_to_epic, class_name: "Epic", optional: true
  has_many :assumptions, dependent: :destroy
  has_many :risks, dependent: :destroy

  validates :name, presence: true
  validates :tshirt_size, inclusion: { in: %w[S M L XL] }, allow_nil: true
  validates :category, inclusion: { in: %w[feature integration infrastructure security performance] }, allow_nil: true
  validates :priority, inclusion: { in: %w[high medium low] }, allow_nil: true
  validates :status, inclusion: { in: %w[draft approved converted rejected] }

  TSHIRT_SIZES = %w[S M L XL].freeze
  CATEGORIES = %w[feature integration infrastructure security performance].freeze
  PRIORITIES = %w[high medium low].freeze
  STATUSES = %w[draft approved converted rejected].freeze

  # T-shirt to rough hours mapping
  TSHIRT_HOURS = { "S" => 8, "M" => 24, "L" => 80, "XL" => 200 }.freeze

  scope :ordered, -> { order(:position, :created_at) }
  scope :approved, -> { where(status: "approved") }
  scope :pending_conversion, -> { approved.where(converted_to_epic_id: nil) }

  def rough_hours
    return nil unless tshirt_size
    TSHIRT_HOURS[tshirt_size]
  end

  def converted?
    converted_to_epic_id.present?
  end
end
