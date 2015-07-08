Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.

  root :to => "home#index"

  devise_for :users
  
  devise_scope :user do
    get "check_session" => "users#check_session"
    get "new_user" => "users#new_user"
    get "show_change_password" => "users#show_change_password"
    get "touch_session" => "users#touch_session"
    patch "change_password"  => "users#change_password"
    post "change_provider" => "users#change_provider"
    post "create_user" => "users#create_user"
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

  resources :trips, :except => [:show] do
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
      post :save_region
      post :save_viewport
    end
  end

  resources :addresses, :only => [:create, :edit, :update, :destroy] do
    collection do
      get :autocomplete
      get :search
    end
  end
  
  resources :device_pools, :except => [:index, :show] do
    resources :device_pool_drivers, :only => [:create, :destroy]
  end
  
  resources :drivers, :except => [:show]
  resources :funding_sources, :except => [:destroy]
  resources :monthlies, :except => [:show, :destroy]
  resources :provider_ethnicities
  resources :vehicles
  resources :vehicle_maintenance_events, :except => [:show, :destroy]

  resources :runs, :except => [:show] do
    collection do
      get :for_date
      get :uncompleted_runs
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
  get "reports", :controller=>:reports, :action=>:index
  get "reports/:action", :controller=>:reports
  get "reports/:action/:id", :controller=>:reports
  get "test_exception_notification" => "application#test_exception_notification"
end
