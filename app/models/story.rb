class Story < ApplicationRecord
  belongs_to :epic
  belongs_to :assigned_user, class_name: "User", foreign_key: "assigned_user_id", optional: true
  has_many :subtasks, dependent: :destroy

  validates :name, presence: true
  validates :points, presence: true, inclusion: { in: [1, 2, 3, 5, 8, 13, 21] }, allow_nil: false

  FIBONACCI_POINTS = [1, 2, 3, 5, 8, 13, 21].freeze

  scope :with_points, -> { where.not(points: nil) }
end
