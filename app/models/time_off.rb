class TimeOff < ApplicationRecord
  belongs_to :user

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :leave_type, presence: true
  validate :end_date_after_start_date

  LEAVE_TYPES = ["Sick Leave", "Vacation", "Personal Leave", "Maternity/Paternity", "Unpaid Leave"].freeze

  scope :in_period, ->(start_date, end_date) {
    where("start_date <= ? AND end_date >= ?", end_date, start_date)
  }

  def days_count
    (end_date - start_date).to_i + 1
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end

