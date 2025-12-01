class StoriesController < ApplicationController
  before_action :set_project
  before_action :set_epic
  before_action :set_story, only: [:edit, :update, :destroy]

  def new
    @story = @epic.stories.build
  end

  def create
    @story = @epic.stories.build(story_params)

    if @story.save
      redirect_to @project, notice: "Story was successfully created."
    else
      redirect_to @project, alert: "Error creating story: #{@story.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @suggester = AssignmentSuggester.new(@project, @story)
    @suggestions = @suggester.suggest
  end

  def update
    if @story.update(story_params)
      redirect_to @project, notice: "Story was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @story.destroy
    redirect_to @project, notice: "Story was successfully deleted."
  end

  def suggest_assignment
    @story = @epic.stories.find(params[:id])
    suggester = AssignmentSuggester.new(@project, @story)
    suggestions = suggester.suggest
    
    render json: {
      suggestions: suggestions.map { |s| { id: s[:user].id, name: s[:user].name, score: s[:score].round(2) } }
    }
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_epic
    @epic = @project.epics.find(params[:epic_id])
  end

  def set_story
    @story = @epic.stories.find(params[:id])
  end

  def story_params
    params.require(:story).permit(:name, :description, :points, :assigned_user_id, :status, :estimated_hours)
  end
end
