class CapacityReportsController < ApplicationController
  before_action :ensure_manager
  before_action :set_user, only: [:show]

  def index
    @users = User.all.order(:name)
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today + 30.days

    @reports = @users.map do |user|
      calculator = CapacityCalculator.new(user, @start_date, @end_date)
      {
        user: user,
        breakdown: calculator.breakdown
      }
    end
  end

  def show
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today + 30.days

    @calculator = CapacityCalculator.new(@user, @start_date, @end_date)
    @breakdown = @calculator.breakdown
    @holidays = @user.holidays.where(date: @start_date..@end_date)
    @time_offs = @user.time_offs.in_period(@start_date, @end_date)
  end

  private

  def ensure_manager
    unless current_user&.manager?
      redirect_to root_path, alert: "You must be a manager to access this page."
    end
  end

  def set_user
    @user = User.find(params[:id])
  end
end
