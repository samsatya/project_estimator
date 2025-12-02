# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_02_182849) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "epics", force: :cascade do |t|
    t.boolean "ai_generated", default: false
    t.datetime "ai_refined_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.integer "jira_epic_id"
    t.string "jira_epic_key"
    t.datetime "last_synced_at"
    t.string "name"
    t.text "original_description"
    t.integer "position"
    t.bigint "project_id", null: false
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["jira_epic_id"], name: "index_epics_on_jira_epic_id"
    t.index ["jira_epic_key"], name: "index_epics_on_jira_epic_key"
    t.index ["project_id"], name: "index_epics_on_project_id"
  end

  create_table "global_holidays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_global_holidays_on_date", unique: true
  end

  create_table "holidays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_holidays_on_user_id"
  end

  create_table "project_teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "team_id"], name: "index_project_teams_on_project_id_and_team_id", unique: true
    t.index ["project_id"], name: "index_project_teams_on_project_id"
    t.index ["team_id"], name: "index_project_teams_on_team_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "aws_access_key_id"
    t.string "aws_model_id", default: "us.anthropic.claude-sonnet-4-20250514-v1:0"
    t.string "aws_region", default: "us-east-1"
    t.string "aws_secret_access_key"
    t.decimal "business_testing_time_percentage", precision: 5, scale: 2, default: "0.15"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "jira_api_token"
    t.string "jira_project_key"
    t.string "jira_site_url"
    t.string "jira_username"
    t.string "name"
    t.decimal "points_to_hours_conversion", precision: 5, scale: 2, default: "8.0"
    t.decimal "pr_review_time_percentage", precision: 5, scale: 2, default: "0.15"
    t.decimal "product_testing_time_percentage", precision: 5, scale: 2, default: "0.2"
    t.date "start_date"
    t.string "status", default: "planning"
    t.boolean "sync_enabled", default: false
    t.date "target_date"
    t.datetime "updated_at", null: false
    t.index ["jira_project_key"], name: "index_projects_on_jira_project_key"
  end

  create_table "stories", force: :cascade do |t|
    t.boolean "ai_generated", default: false
    t.datetime "ai_refined_at"
    t.integer "ai_suggested_points"
    t.bigint "assigned_user_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.bigint "epic_id", null: false
    t.decimal "estimated_hours", precision: 10, scale: 2
    t.integer "jira_issue_id"
    t.string "jira_issue_key"
    t.datetime "last_synced_at"
    t.string "name"
    t.text "original_description"
    t.integer "points"
    t.date "start_date"
    t.string "status"
    t.string "task_type"
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_stories_on_assigned_user_id"
    t.index ["epic_id"], name: "index_stories_on_epic_id"
    t.index ["jira_issue_id"], name: "index_stories_on_jira_issue_id"
    t.index ["jira_issue_key"], name: "index_stories_on_jira_issue_key"
  end

  create_table "subtasks", force: :cascade do |t|
    t.bigint "assigned_user_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "estimated_hours", precision: 10, scale: 2
    t.string "name"
    t.string "status"
    t.bigint "story_id", null: false
    t.string "task_type"
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_subtasks_on_assigned_user_id"
    t.index ["story_id"], name: "index_subtasks_on_story_id"
  end

  create_table "team_member_projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_team_member_projects_on_project_id"
    t.index ["user_id"], name: "index_team_member_projects_on_user_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "time_offs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "leave_type"
    t.text "reason"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_time_offs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "primary_strength"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "team_member"
    t.string "secondary_strength"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "epics", "projects"
  add_foreign_key "holidays", "users"
  add_foreign_key "project_teams", "projects"
  add_foreign_key "project_teams", "teams"
  add_foreign_key "stories", "epics"
  add_foreign_key "stories", "users", column: "assigned_user_id"
  add_foreign_key "subtasks", "stories"
  add_foreign_key "subtasks", "users", column: "assigned_user_id"
  add_foreign_key "team_member_projects", "projects"
  add_foreign_key "team_member_projects", "users"
  add_foreign_key "team_members", "teams"
  add_foreign_key "team_members", "users"
  add_foreign_key "time_offs", "users"
end
