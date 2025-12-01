# Project Estimator

A full-stack Rails 8 application for project estimation and timeline planning. This application helps teams estimate project delivery timelines by breaking down projects into epics, stories, and subtasks, and calculating estimates based on story points, team member skills, and buffer times.

## Features

- **Hierarchical Project Structure**: Projects → Epics → Stories → Subtasks
- **Story Pointing**: Fibonacci-based story pointing (1, 2, 3, 5, 8, 13, 21)
- **Team Management**: Add team members with primary and secondary skills
- **Smart Assignment**: AI-suggested assignments based on team member skills
- **Estimation Calculation**: Automatic calculation including:
  - Story hours (based on points)
  - PR Review time buffer
  - Product testing time buffer
  - Business user testing time buffer
- **Dashboard & Charts**: Visual representation of:
  - Story points by epic
  - Team member workload distribution
  - Skill utilization
- **Iterative Editing**: Save and edit estimations as you refine your project plan

## Tech Stack

- **Backend**: Ruby on Rails 8
- **Database**: PostgreSQL
- **Authentication**: Devise
- **Frontend**: ERB views with Hotwire (Turbo + Stimulus)
- **Styling**: Tailwind CSS
- **Charts**: Chart.js

## Setup

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

3. Start the server:
   ```bash
   bin/dev
   ```

   Or separately:
   ```bash
   rails server
   # In another terminal:
   bin/rails tailwindcss:watch
   ```

4. Visit `http://localhost:3000` and sign up for an account.

## Usage

1. **Create Team Members**: Go to "Team Members" and add team members with their primary and secondary skills.

2. **Create a Project**: Create a new project and configure estimation settings (points-to-hours conversion, buffer percentages).

3. **Add Team Members to Project**: On the project page, add team members who will work on the project.

4. **Create Epics**: Add epics to organize your project.

5. **Create Stories**: Add stories under epics with story points. You can assign stories to team members manually or use the smart suggestions.

6. **Create Subtasks**: Break down stories into subtasks with estimated hours.

7. **View Dashboard**: Click "Dashboard" on any project to see visualizations and detailed breakdowns.

## Estimation Formula

```
Total Hours = Story Hours × (1 + PR Review % + Product Testing % + Business Testing %)

Where:
- Story Hours = Story Points × Points-to-Hours Conversion Factor
```

## Default Settings

- Points to Hours Conversion: 8 hours per point
- PR Review Time: 15% of story hours
- Product Testing Time: 20% of story hours
- Business Testing Time: 15% of story hours

These can be customized per project.

## Development

Run the test suite:
```bash
rails test
```

## License

This project is open source and available under the MIT License.
