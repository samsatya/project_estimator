class SubtasksController < ApplicationController
  before_action :set_project
  before_action :set_epic
  before_action :set_story
  before_action :set_subtask, only: [:edit, :update, :destroy]

  def new
    @subtask = @story.subtasks.build
  end

  def create
    @subtask = @story.subtasks.build(subtask_params)

    if @subtask.save
      redirect_to @project, notice: "Subtask was successfully created."
    else
      redirect_to @project, alert: "Error creating subtask: #{@subtask.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @suggester = AssignmentSuggester.new(@project, @subtask)
    @suggestions = @suggester.suggest
  end

  def update
    if @subtask.update(subtask_params)
      redirect_to @project, notice: "Subtask was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @subtask.destroy
    redirect_to @project, notice: "Subtask was successfully deleted."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_epic
    @epic = @project.epics.find(params[:epic_id])
  end

  def set_story
    @story = @epic.stories.find(params[:story_id])
  end

  def set_subtask
    @subtask = @story.subtasks.find(params[:id])
  end

  def subtask_params
    params.require(:subtask).permit(:name, :description, :assigned_user_id, :estimated_hours, :status, :task_type)
  end
end
