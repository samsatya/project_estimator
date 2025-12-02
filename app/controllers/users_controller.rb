class UsersController < ApplicationController
  before_action :ensure_manager
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.all.order(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to team_members_path, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to team_members_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      redirect_to team_members_path, notice: "User was successfully deleted."
    else
      redirect_to team_members_path, alert: "Unable to delete user: #{@user.errors.full_messages.join(', ')}"
    end
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

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :primary_strength, :secondary_strength, :capacity, :role)
  end
end
