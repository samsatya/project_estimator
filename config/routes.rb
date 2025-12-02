Rails.application.routes.draw do
  root "home#index"

  devise_for :users

  # Team member management routes - using different path to avoid conflict with Devise
  resources :users, except: [:show], path: "team_members", as: "team_members", controller: "users" do
    resources :holidays, except: [:show]
    resources :time_offs, except: [:show]
  end

  # Global holidays (manager only)
  resources :global_holidays, except: [:show] do
    collection do
      get :bulk_upload
      post :process_bulk_upload
      get :download_template
    end
  end

  # Capacity reports for managers
  resources :capacity_reports, only: [:index, :show]

  resources :projects do
    resources :epics, except: [:index, :show] do
      member do
        get :bulk_upload
        post :process_bulk_upload
        get :download_template
        get :export_to_jira
      end
      resources :stories, except: [:index, :show] do
        member do
          post :suggest_assignment
        end
        resources :subtasks, except: [:index, :show]
      end
    end
    member do
      get :dashboard
      get :export
      get :gantt_chart
      get :pivot_report
      get :jira_config
      patch :update_jira_config
      post :test_jira_connection
      post :sync_to_jira
      post :sync_from_jira
      post :add_team_member
      delete :remove_team_member
      post :add_team
      delete :remove_team
    end
  end
  
  resources :teams do
    member do
      post :add_member
      delete :remove_member
    end
    resources :availability_calendar, only: [:index], controller: "availability_calendar"
    resources :team_calendar, only: [:index], controller: "team_calendar"
  end
  
  # Availability Calendar
  resources :availability_calendar, only: [:index]
  get "availability_calendar/user/:user_id", to: "availability_calendar#index", as: "user_availability_calendar"

  get "up" => "rails/health#show", as: :rails_health_check
end
