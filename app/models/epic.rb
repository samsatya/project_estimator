class Epic < ApplicationRecord
  belongs_to :project
  has_many :stories, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
