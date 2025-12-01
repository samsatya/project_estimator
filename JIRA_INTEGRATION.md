# Jira Integration Guide

This application supports bi-directional synchronization with Jira. You can export epics and stories to Jira, and import them back.

## Setup

### 1. Get Your Jira API Token

1. Go to [Atlassian Account Settings](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click "Create API token"
3. Copy the generated token (you'll only see it once!)

### 2. Configure Jira in Project

1. Go to your project
2. Click "Setup Jira" or "Jira Config" button
3. Fill in the following:
   - **Jira Site URL**: Your Jira instance URL (e.g., `https://your-domain.atlassian.net`)
   - **Jira Username/Email**: Your Jira account email
   - **Jira API Token**: The token you generated in step 1
   - **Jira Project Key**: The short key for your Jira project (e.g., "PROJ", "TEST")
4. Click "Test Connection" to verify
5. Click "Save Configuration"

## Features

### Export to Jira (Sync To Jira)

- Exports all epics and stories from the application to Jira
- Creates new Jira issues if they don't exist
- Updates existing Jira issues if they're already synced
- Links stories to their parent epics in Jira

### Import from Jira (Sync From Jira)

- Imports all epics and stories from Jira to the application
- Creates new records if they don't exist
- Updates existing records based on Jira issue keys
- Maintains the relationship between epics and stories

### Bi-directional Sync

- Epics and stories are linked via Jira issue keys
- Changes can be synced in either direction
- Last sync timestamp is tracked for each record

## Jira Field Mappings

### Epics
- **Name** → Jira Summary
- **Description** → Jira Description
- **Epic Name** → Custom Field (customfield_10011)

### Stories
- **Name** → Jira Summary
- **Description** → Jira Description
- **Points** → Story Points (customfield_10016)
- **Epic Link** → Epic Link (customfield_10014)

## Important Notes

1. **Custom Field IDs**: The service uses common Jira custom field IDs. If your Jira instance uses different field IDs, you may need to update the `JiraService` class.

2. **Mandatory Fields**: When you provide the list of mandatory fields, we'll update the service to ensure they're included during sync.

3. **Sync Conflicts**: The current implementation uses "last write wins" strategy. If you need conflict resolution, we can enhance this.

4. **API Rate Limits**: Jira has rate limits. For large projects, consider syncing in batches.

5. **Epic Link Field**: The epic link field ID (customfield_10014) may vary by Jira instance. Check your Jira configuration.

## Troubleshooting

### Connection Failed
- Verify your Jira site URL is correct
- Check that your API token is valid
- Ensure your username/email is correct
- Make sure the project key exists in Jira

### Sync Errors
- Check that the Jira project has Epic and Story issue types configured
- Verify custom field IDs match your Jira instance
- Check Jira API logs for detailed error messages

### Missing Fields
- Some fields may not sync if they're not configured in your Jira instance
- Custom fields need to be added to the appropriate issue types
- Contact your Jira administrator to configure required fields

## Future Enhancements

- Automatic sync on save (when enabled)
- Conflict resolution UI
- Sync history and logs
- Support for subtasks sync
- Custom field mapping configuration

