#!/usr/bin/env ruby

# Find the existing epic
project = Project.find_by(name: "Planner to OMS")
epic = project.epics.first

puts "Importing to Project: #{project.name}"
puts "Epic: #{epic.name}"

# Read the CSV file
csv_content = File.read("planning_module_import.csv")

# Create the service and import
service = BulkUploadService.new(epic)
success = service.import_from_csv(csv_content)

if success
  puts "CSV import successful!"
  puts "Stories imported: #{service.imported_count[:stories]}"
  puts "Subtasks imported: #{service.imported_count[:subtasks]}"
else
  puts "CSV import failed with errors:"
  service.errors.each { |error| puts "  - #{error}" }
end