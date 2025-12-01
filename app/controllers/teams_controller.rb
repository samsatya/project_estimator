class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  def index
    @teams = Team.all.includes(:users).order(created_at: :desc)
  end

  def show
    @available_users = User.where.not(id: @team.user_ids)
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to @team, notice: "Team was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_users = User.where.not(id: @team.user_ids)
  end

  def update
    if @team.update(team_params)
      redirect_to @team, notice: "Team was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team.destroy
    redirect_to teams_path, notice: "Team was successfully deleted."
  end

  def add_member
    @team = Team.find(params[:id])
    @available_users = User.where.not(id: @team.user_ids)
    
    user_id = params[:user_id] || params.dig(:user, :user_id)
    
    if user_id.blank?
      redirect_to @team, alert: "Please select a team member."
      return
    end
    
    user = User.find(user_id)
    
    if @team.users.include?(user)
      redirect_to @team, alert: "#{user.name} is already in the team."
      return
    end
    
    @team.users << user
    
    if @team.save
      redirect_to @team, notice: "#{user.name} added to team."
    else
      redirect_to @team, alert: "Error adding user to team: #{@team.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordNotFound => e
    redirect_to @team, alert: "User not found: #{e.message}"
  rescue => e
    redirect_to @team, alert: "Error: #{e.message}"
  end

  def remove_member
    @team = Team.find(params[:id])
    
    if params[:user_id].blank?
      redirect_to @team, alert: "User ID is required."
      return
    end
    
    user = User.find(params[:user_id])
    @team.users.delete(user)
    redirect_to @team, notice: "#{user.name} removed from team."
  rescue ActiveRecord::RecordNotFound
    redirect_to @team, alert: "User not found."
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description)
  end
end
