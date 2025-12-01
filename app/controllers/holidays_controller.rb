class HolidaysController < ApplicationController
  before_action :set_user
  before_action :ensure_authorized
  before_action :set_holiday, only: [:edit, :update, :destroy]

  def index
    @holidays = @user.holidays.order(:date)
  end

  def new
    @holiday = @user.holidays.build
  end

  def create
    @holiday = @user.holidays.build(holiday_params)

    if @holiday.save
      redirect_to team_member_holidays_path(@user), notice: "Holiday was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @holiday.update(holiday_params)
      redirect_to team_member_holidays_path(@user), notice: "Holiday was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @holiday.destroy
    redirect_to team_member_holidays_path(@user), notice: "Holiday was successfully deleted."
  end

  private

  def ensure_authorized
    # Users can only manage their own holidays/time offs, unless they're managers
    unless current_user&.manager? || @user == current_user
      redirect_to root_path, alert: "You can only manage your own holidays."
    end
  end

  def set_user
    @user = User.find(params[:team_member_id] || params[:user_id])
  end

  def set_holiday
    @holiday = @user.holidays.find(params[:id])
  end

  def holiday_params
    params.require(:holiday).permit(:date, :name)
  end
end
