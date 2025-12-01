class Subtask < ApplicationRecord
  belongs_to :story
  belongs_to :assigned_user, class_name: "User", foreign_key: "assigned_user_id", optional: true

  validates :name, presence: true
  validates :estimated_hours, numericality: { greater_than: 0 }, allow_nil: true
end
