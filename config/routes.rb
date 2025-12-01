Rails.application.routes.draw do
  root "home#index"

  devise_for :users

  # Team member management routes - using different path to avoid conflict with Devise
  resources :users, except: [:show], path: "team_members", as: "team_members", controller: "users" do
    resources :holidays, except: [:show]
    resources :time_offs, except: [:show]
  end

  # Capacity reports for managers
  resources :capacity_reports, only: [:index, :show]

  resources :projects do
    resources :epics, except: [:index, :show] do
      member do
        get :bulk_upload
        post :process_bulk_upload
        get :download_template
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
  end
  
  get "up" => "rails/health#show", as: :rails_health_check
end
