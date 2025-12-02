class Subtask < ApplicationRecord
  belongs_to :story
  belongs_to :assigned_user, class_name: "User", foreign_key: "assigned_user_id", optional: true

  validates :name, presence: true
  validates :estimated_hours, numericality: { greater_than: 0 }, allow_nil: true
  validates :task_type, inclusion: { in: %w[development testing design research documentation UI Backend Infra Test] }, allow_nil: true

  TASK_TYPES = %w[development testing design research documentation UI Backend Infra Test].freeze
end
