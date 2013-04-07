WitnessSupportBooking::Application.routes.draw do

  resources :courts, :only => [ :create, :index, :edit, :update, :destroy]
  resources( :users){ member{ put :disable; put :enable; put :promote}}
  resources :user_sessions, :only => [:new, :create, :destroy]
  # CourtDay business logic needs update-or-create( date), in which case PUT
  # is correct (idempotent!) and hence #update handles creation as well.
  resources :court_days, :only => [ :index, :update]
  # Conceptually a booking is normally part of the user resource.  But when
  # the Administrator unbooks a user it is more straigthtforward to view it as
  # a resource in its own right.
  resources :bookings, :only => [ :destroy]
  resource :database, :only => [ :new, :create, :show]
  root :to => "static_pages#home"
  match "/sign_up", :to => "users#new"
  match "/log_in",  :to => "user_sessions#new"
  match "/log_out", :to => "user_sessions#destroy"
  match "/about",   :to => "static_pages#about"
  match "/help",    :to => "static_pages#help"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
