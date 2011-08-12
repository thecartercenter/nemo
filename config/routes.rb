CommandCenter::Application.routes.draw do
  resource(:user_session)
  resources(:broadcasts){collection{post 'new_with_users'}}
  resources(:forms){member{post 'add_questions', 'remove_questions', 'update_ranks'; get 'publish'}}
  resources(:languages)
  resources(:options)
  resources(:option_sets)
  resources(:password_resets)
  resources(:permissions){collection{get 'no'}}
  resources(:places){collection{get 'map'}}
  resources(:place_lookups){collection{get 'suggest'}}
  resources(:questionings)
  resources(:questions){collection{get 'choose'}}
  resources(:responses)
  resources(:searches){member{get 'clear'}; collection{get 'start'}}
  resources(:settings){collection{post 'update_all'}}
  resources(:users)


  root(:to => "welcome#index")
  
  # redirects for ODK
  match("/formList" => 'forms#index', :format => :xml)
  match("/submission" => 'responses#create', :format => :xml)
  
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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
