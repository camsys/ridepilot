Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.

  scope "(:locale)", locale: TranslationEngine.available_locales do

    mount TranslationEngine::Engine => "/translation_engine"

    root :to => "home#index"

    devise_for :users
    
    devise_scope :user do
      get "new_user" => "users#new_user"
      post "create_user" => "users#create_user"
      get "show_change_password" => "users#show_change_password"
      patch "change_password"  => "users#change_password"
      get "show_change_expiration" => "users#show_change_expiration"
      patch "change_expiration"  => "users#change_expiration"
      post "change_provider" => "users#change_provider"
      get "check_session" => "users#check_session"
      get "touch_session" => "users#touch_session"
    end

    resource :application_settings, only: [:edit, :update] do
      collection do
        get :index
      end
    end

    resources :customers do
      post :inactivate, :as => :inactivate
      
      collection do
        get :all
        get :autocomplete
        get :found
        get :search
      end
    end

    resources :trips do
      post :confirm
      post :no_show
      post :reached
      post :send_to_cab
      post :turndown

      collection do
        get :reconcile_cab
        get :trips_requiring_callback
        get :unscheduled
      end
    end

    resources :providers, :except => [:edit, :update, :destroy] do
      post :change_role
      post :delete_role
      member do
        post :change_dispatch
        post :change_reimbursement_rates
        post :change_scheduling
        post :change_allow_trip_entry_from_runs_page
        post :change_fields_required_for_run_completion
        post :save_region
        post :save_viewport
      end
    end
    
    resources :recurring_driver_compliances do
      collection do
        get :schedule_preview
        get :future_schedule_preview
        get :compliance_based_schedule_preview
        put :generate, action: "generate!"
      end
      member do
        get :delete
      end
    end

    resources :recurring_vehicle_maintenance_compliances do
      collection do
        get :schedule_preview
        get :future_schedule_preview
        get :compliance_based_schedule_preview
        put :generate, action: "generate!"
      end
      member do
        get :delete
      end
    end

    resources :addresses, :only => [:create, :edit, :update, :destroy] do
      collection do
        post :validate
        get :autocomplete
        get :search
        patch :upload
        get :check_loading_status
      end
    end
    get "check_address_loading_status" => "addresses#check_loading_status"
    
    resources :device_pools, :except => [:index, :show] do
      resources :device_pool_drivers, :only => [:create, :destroy]
    end
    
    resources :drivers do
      resources :documents, except: [:index, :show]
      resources :driver_histories, except: [:index, :show]
      resources :driver_compliances, except: [:index, :show]
    end
    resources :funding_sources, :except => [:destroy]
    resources :monthlies, :except => [:show, :destroy]
    resources :provider_ethnicities
    resources :vehicles do
      resources :documents, except: [:index, :show]
      resources :vehicle_maintenance_events, :except => [:index, :show]
      resources :vehicle_maintenance_compliances, :except => [:index, :show]
      resources :vehicle_warranties, :except => [:index, :show]
    end

    resources :runs do
      collection do
        get :for_date
        get :uncompleted_runs
      end
    end

    resources :trips_runs, only: [:index] do 
      collection do 
        post :schedule
      end
    end
    
    resources :cab_trips, :only => [:index] do
      collection do
        get :edit_multiple
        put :update_multiple
      end
    end

    scope :via => :post, :constraints => { :format => "json" , :protocol => "https://" } do
      match "device_pool_drivers/" => "v1/device_pool_drivers#index", :as => "v1_device_pool_drivers"
      match "v1/device_pool_drivers/:id" => "v1/device_pool_drivers#update", :as => "v1_device_pool_driver"
    end
    
    get "dispatch", :controller => :dispatch, :action => :index
    #get "reports", :controller=>:reports, :action=>:index
    get "custom_reports/:id", :controller=>:reports, :action=>:show, as: :custom_report
    get "reports/:action", :controller=>:reports
    get "reports/:action/:id", :controller=>:reports
    # reporting engine
    mount Reporting::Engine, at: "/reporting"
    

    get "test_exception_notification" => "application#test_exception_notification"

    resources :lookup_tables, :only => [:index, :show] do 
      member do
        post :add_value
        put :update_value
        put :destroy_value
      end
    end
  end
end
