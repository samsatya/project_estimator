class Holiday < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :name, presence: true
end
