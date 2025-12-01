class JiraService
  attr_reader :client, :project, :errors

  def initialize(project)
    @project = project
    @errors = []
    
    return unless jira_configured?

    begin
      require 'jira-ruby' unless defined?(JIRA)
    rescue LoadError => e
      @errors << "Jira gem not available: #{e.message}. Please restart your Rails server after installing the gem."
      @client = nil
      return
    end

    options = {
      username: project.jira_username,
      password: project.jira_api_token,
      site: project.jira_site_url,
      context_path: '',
      auth_type: :basic,
      use_ssl: project.jira_site_url.start_with?('https')
    }

    begin
      @client = JIRA::Client.new(options)
      # Test connection only if project key is present
      @client.Project.find(project.jira_project_key) if project.jira_project_key.present?
    rescue LoadError => e
      @errors << "Jira gem not available: #{e.message}. Please restart your Rails server."
      @client = nil
    rescue JIRA::HTTPError => e
      @errors << "Jira connection failed: #{e.message}"
      @client = nil
    rescue StandardError => e
      @errors << "Jira initialization error: #{e.message}"
      @client = nil
    end
  end

  def jira_configured?
    project.jira_site_url.present? &&
      project.jira_username.present? &&
      project.jira_api_token.present? &&
      project.jira_project_key.present?
  end

  def connected?
    @client.present? && @errors.empty?
  end

  # Export epic to Jira
  def create_epic(epic)
    return { success: false, error: "Jira not configured" } unless jira_configured?
    return { success: false, error: "Not connected to Jira" } unless connected?

    begin
      epic_issue = @client.Issue.build
      epic_issue.save({
        'fields' => {
          'project' => { 'key' => @project.jira_project_key },
          'summary' => epic.name,
          'description' => epic.description || '',
          'issuetype' => { 'name' => 'Epic' },
          'customfield_10011' => epic.name # Epic Name field (common custom field ID)
        }
      })

      epic.update_columns(
        jira_epic_key: epic_issue.key,
        jira_epic_id: epic_issue.id.to_i,
        last_synced_at: Time.current
      )

      { success: true, epic_key: epic_issue.key, epic_id: epic_issue.id }
    rescue JIRA::HTTPError => e
      { success: false, error: "Failed to create epic: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Error creating epic: #{e.message}" }
    end
  end

  # Update epic in Jira
  def update_epic(epic)
    return { success: false, error: "Epic not synced to Jira" } unless epic.jira_epic_key.present?
    return { success: false, error: "Not connected to Jira" } unless connected?

    begin
      epic_issue = @client.Issue.find(epic.jira_epic_key)
      epic_issue.save({
        'fields' => {
          'summary' => epic.name,
          'description' => epic.description || '',
          'customfield_10011' => epic.name # Epic Name
        }
      })

      epic.update_column(:last_synced_at, Time.current)
      { success: true }
    rescue JIRA::HTTPError => e
      { success: false, error: "Failed to update epic: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Error updating epic: #{e.message}" }
    end
  end

  # Export story to Jira
  def create_story(story, epic_key = nil)
    return { success: false, error: "Jira not configured" } unless jira_configured?
    return { success: false, error: "Not connected to Jira" } unless connected?

    begin
      story_fields = {
        'project' => { 'key' => @project.jira_project_key },
        'summary' => story.name,
        'description' => story.description || '',
        'issuetype' => { 'name' => 'Story' },
        'customfield_10016' => story.points # Story Points (common custom field ID)
      }

      # Link to epic if provided
      if epic_key.present?
        story_fields['customfield_10014'] = epic_key # Epic Link (common custom field ID)
      end

      story_issue = @client.Issue.build
      story_issue.save({ 'fields' => story_fields })

      story.update_columns(
        jira_issue_key: story_issue.key,
        jira_issue_id: story_issue.id.to_i,
        last_synced_at: Time.current
      )

      { success: true, story_key: story_issue.key, story_id: story_issue.id }
    rescue JIRA::HTTPError => e
      { success: false, error: "Failed to create story: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Error creating story: #{e.message}" }
    end
  end

  # Update story in Jira
  def update_story(story)
    return { success: false, error: "Story not synced to Jira" } unless story.jira_issue_key.present?
    return { success: false, error: "Not connected to Jira" } unless connected?

    begin
      story_issue = @client.Issue.find(story.jira_issue_key)
      
      update_fields = {
        'summary' => story.name,
        'description' => story.description || '',
        'customfield_10016' => story.points # Story Points
      }

      # Update epic link if story belongs to an epic with Jira sync
      if story.epic.jira_epic_key.present?
        update_fields['customfield_10014'] = story.epic.jira_epic_key
      end

      story_issue.save({ 'fields' => update_fields })

      story.update_column(:last_synced_at, Time.current)
      { success: true }
    rescue JIRA::HTTPError => e
      { success: false, error: "Failed to update story: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Error updating story: #{e.message}" }
    end
  end

  # Sync all epics and stories from Jira to local
  def sync_from_jira
    return { success: false, error: "Jira not configured" } unless jira_configured?
    return { success: false, error: "Not connected to Jira" } unless connected?

    synced_count = { epics: 0, stories: 0 }
    errors = []

    begin
      # Sync epics
      jql = "project = #{@project.jira_project_key} AND issuetype = Epic"
      epics = @client.Issue.jql(jql)

      epics.each do |jira_epic|
        epic = @project.epics.find_or_initialize_by(jira_epic_key: jira_epic.key)
        epic.name = jira_epic.summary
        epic.description = jira_epic.description
        epic.jira_epic_id = jira_epic.id.to_i
        epic.last_synced_at = Time.current

        if epic.save
          synced_count[:epics] += 1
        else
          errors << "Failed to save epic #{jira_epic.key}: #{epic.errors.full_messages.join(', ')}"
        end
      end

      # Sync stories
      jql = "project = #{@project.jira_project_key} AND issuetype = Story"
      stories = @client.Issue.jql(jql)

      stories.each do |jira_story|
        story = @project.stories.find_or_initialize_by(jira_issue_key: jira_story.key)
        story.name = jira_story.summary
        story.description = jira_story.description
        story.jira_issue_id = jira_story.id.to_i
        story.points = jira_story.customfield_10016 || story.points # Story points
        story.last_synced_at = Time.current

        # Link to epic if epic link exists
        if jira_story.customfield_10014.present?
          epic_key = jira_story.customfield_10014
          epic = @project.epics.find_by(jira_epic_key: epic_key)
          story.epic = epic if epic
        end

        if story.save
          synced_count[:stories] += 1
        else
          errors << "Failed to save story #{jira_story.key}: #{story.errors.full_messages.join(', ')}"
        end
      end

      {
        success: true,
        synced_count: synced_count,
        errors: errors
      }
    rescue JIRA::HTTPError => e
      { success: false, error: "Jira API error: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Sync error: #{e.message}" }
    end
  end

  # Export all epics and stories to Jira
  def sync_to_jira
    return { success: false, error: "Jira not configured" } unless jira_configured?
    return { success: false, error: "Not connected to Jira" } unless connected?

    synced_count = { epics: 0, stories: 0 }
    errors = []

    # Sync epics first
    @project.epics.each do |epic|
      if epic.jira_epic_key.present?
        result = update_epic(epic)
      else
        result = create_epic(epic)
      end

      if result[:success]
        synced_count[:epics] += 1
      else
        errors << "Epic '#{epic.name}': #{result[:error]}"
      end
    end

    # Sync stories
    @project.stories.each do |story|
      if story.jira_issue_key.present?
        result = update_story(story)
      else
        epic_key = story.epic&.jira_epic_key
        result = create_story(story, epic_key)
      end

      if result[:success]
        synced_count[:stories] += 1
      else
        errors << "Story '#{story.name}': #{result[:error]}"
      end
    end

    {
      success: errors.empty?,
      synced_count: synced_count,
      errors: errors
    }
  end

  # Test Jira connection
  def test_connection
    return { success: false, error: "Jira not configured" } unless jira_configured?
    return { success: false, error: "Not connected to Jira. #{@errors.join(', ')}" } unless connected?

    begin
      require 'jira-ruby' unless defined?(JIRA)
      project = @client.Project.find(@project.jira_project_key)
      { success: true, project_name: project.name }
    rescue LoadError => e
      { success: false, error: "Jira gem not available: #{e.message}" }
    rescue JIRA::HTTPError => e
      { success: false, error: "Connection failed: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Error: #{e.message}" }
    end
  end
end

