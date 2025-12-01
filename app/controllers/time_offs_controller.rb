class TimeOffsController < ApplicationController
  before_action :set_user
  before_action :ensure_authorized
  before_action :set_time_off, only: [:edit, :update, :destroy]

  def index
    @time_offs = @user.time_offs.order(:start_date)
  end

  def new
    @time_off = @user.time_offs.build
  end

  def create
    @time_off = @user.time_offs.build(time_off_params)

    if @time_off.save
      redirect_to team_member_time_offs_path(@user), notice: "Time off was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @time_off.update(time_off_params)
      redirect_to team_member_time_offs_path(@user), notice: "Time off was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_off.destroy
    redirect_to team_member_time_offs_path(@user), notice: "Time off was successfully deleted."
  end

  private

  def ensure_authorized
    # Users can only manage their own holidays/time offs, unless they're managers
    unless current_user&.manager? || @user == current_user
      redirect_to root_path, alert: "You can only manage your own time off."
    end
  end

  def set_user
    @user = User.find(params[:team_member_id] || params[:user_id])
  end

  def set_time_off
    @time_off = @user.time_offs.find(params[:id])
  end

  def time_off_params
    params.require(:time_off).permit(:start_date, :end_date, :leave_type, :reason)
  end
end
