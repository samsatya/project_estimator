# Bulk Upload CSV Format

This document describes the CSV format for bulk uploading stories and subtasks to an epic.

## CSV File Structure

The CSV file must contain the following columns (in any order):

### Required Columns

- **Story Name** - The name of the story (required when creating a new story)
- **Story Points** - Must be one of: `1`, `2`, `3`, `5`, `8`, `13`, `21` (Fibonacci sequence)

### Optional Columns

- **Story Description** - Description of the story
- **Story Assigned To** - User name or email address
- **Story Status** - One of: `not_started`, `in_progress`, `completed`, `blocked`
- **Subtask Name** - Name of the subtask (requires a story in the same or previous row)
- **Subtask Estimated Hours** - Number of hours (decimal values allowed, e.g., 4.5)
- **Subtask Description** - Description of the subtask
- **Subtask Assigned To** - User name or email address
- **Subtask Status** - One of: `not_started`, `in_progress`, `completed`, `blocked`

## How It Works

1. **Stories**: Each row with a `Story Name` creates or updates a story. If a story with the same name already exists, it will be updated (not duplicated).

2. **Subtasks**: Rows with a `Subtask Name` create subtasks. The subtask belongs to the most recent story (either in the same row or a previous row).

3. **Multiple Subtasks per Story**: To add multiple subtasks to the same story, leave the `Story Name` column empty in subsequent rows. The subtasks will be associated with the last story that had a name.

## Example CSV

```csv
Story Name,Story Points,Story Description,Story Assigned To,Story Status,Subtask Name,Subtask Estimated Hours,Subtask Description,Subtask Assigned To,Subtask Status
User Authentication,5,Implement login and registration,john@example.com,not_started,Create login form,4,Design and implement login UI,jane@example.com,not_started
,,,,,Create registration form,6,Design and implement registration UI,jane@example.com,not_started
User Dashboard,8,Build user dashboard,bob@example.com,in_progress,Design dashboard layout,8,Create wireframes and design,alice@example.com,completed
,,,,,Implement dashboard API,12,Create REST API endpoints,bob@example.com,in_progress
```

## Notes

- Column names are case-insensitive
- Empty cells are allowed for optional fields
- User assignment can be done by name or email (case-insensitive)
- If a user is not found by name/email, the assignment will be skipped (no error)
- Story points must be valid Fibonacci numbers (1, 2, 3, 5, 8, 13, 21)
- Status values must match exactly: `not_started`, `in_progress`, `completed`, `blocked`
- Estimated hours must be positive numbers (decimals allowed)

## Error Handling

If there are errors during import:
- The import will continue processing all rows
- All errors will be displayed at the end
- Successfully imported items will be saved
- Failed items will be skipped with error messages

## Download Template

You can download a template CSV file from the bulk upload page. The template includes:
- All column headers
- Example data showing the format
- Multiple stories with subtasks

