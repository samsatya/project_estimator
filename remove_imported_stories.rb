#!/usr/bin/env ruby

# Find the epic
project = Project.find_by(name: "Planner to OMS")
epic = project.epics.first

puts "Removing stories from Epic: #{epic.name}"
puts "Project: #{project.name}"

# Get all stories in the epic
stories = epic.stories.includes(:subtasks)

puts "Found #{stories.count} stories to remove"

# Remove all stories (this will also cascade delete subtasks)
stories.each_with_index do |story, index|
  puts "Removing story #{index + 1}/#{stories.count}: #{story.name}"
  story.destroy!
end

puts "Successfully removed all #{stories.count} stories from the epic"

# Verify cleanup
remaining_stories = epic.reload.stories.count
puts "Remaining stories in epic: #{remaining_stories}"