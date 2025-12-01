class GlobalHoliday < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :name, presence: true

  scope :in_period, ->(start_date, end_date) {
    where(date: start_date..end_date)
  }

  scope :upcoming, -> {
    where("date >= ?", Date.current).order(:date)
  }

  scope :by_year, ->(year) {
    where("EXTRACT(YEAR FROM date) = ?", year)
  }
end
