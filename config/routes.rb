ELMO::Application.routes.draw do

  # proxies for ajax same-origin
  match 'proxies/:action', :controller => 'proxies'

  #####################################
  # Basic routes (neither mission nor admin mode)
  scope '(:locale)', :locale => /[a-z]{2}/ do
    resources :password_resets
    resource :user_session

    # For viewing/editing user profiles, which is neither mode
    resources :users, :only => %w(show edit update)

    # login/logout shortcuts
    get '/logged-out' => 'user_sessions#logged_out', :as => :logged_out
    match '/logout' => 'user_sessions#destroy', :as => :logout
    get '/login' => 'user_sessions#new', :as => :login

    # /en/, /en
    root :to => 'welcome#index', :as => :basic_root
  end

  #####################################
  # Admin-mode-only routes
  scope '(:locale)/:mode', :locale => /[a-z]{2}/, :mode => /admin/ do
    resources :missions

    # for /en/admin
    root :to => 'welcome#index', :as => :admin_root
  end

  #####################################
  # Mission-mode-only routes
  scope '(:locale)/:mode/:mission_id', :locale => /[a-z]{2}/, :mode => /m/, :mission_id => /[a-z][a-z0-9]*/ do
    resources(:broadcasts) do
      collection do
        post 'new_with_users', :path => 'new-with-users'
      end
    end
    resources :responses
    resources :sms, :only => [:index, :create]
    resources :sms_tests, :path => 'sms-tests'

    namespace :report  do
      resources :reports

      # need to list these all separately b/c rails is dumb sometimes
      resources :question_answer_tally_reports, :controller => 'reports'
      resources :grouped_tally_reports, :controller => 'reports'
      resources :list_reports, :controller => 'reports'
      resources :standard_form_reports, :controller => 'reports'
    end

    # special dashboard routes
    match '/info-window' => 'welcome#info_window', :as => :dashboard_info_window
    get '/report-update/:id' => 'welcome#report_update'

    # for /en/m/mission123
    root :to => 'welcome#index', :as => :mission_root
  end

  #####################################
  # Admin mode OR mission mode routes
  scope '(:locale)/:mode(/:mission_id)', :locale => /[a-z]{2}/, :mode => /m|admin/, :mission_id => /[a-z][a-z0-9]*/ do

    # the rest of these routes can have admin mode or not
    resources :forms do
      member do
        post 'add_questions', :path => 'add-questions'
        post 'remove_questions', :path => 'remove-questions'
        put 'clone'
        put 'publish'
        get 'choose_questions', :path => 'choose-questions'
      end
    end
    resources :markers
    resources :questions
    resources :questionings
    resources :settings
    resources :users do
      member do
        get 'login_instructions', :path => 'login-instructions'
        get 'exit_admin_mode', :path => 'exit-admin-mode'
      end
      post 'export', :on => :collection
    end
    resources :user_batches, :path => 'user-batches'
    resources :groups

    resources :option_sets, :path => 'option-sets' do
      put 'clone', :on => :member
    end

    # import routes for standardizeable objects
    %w(forms questions option_sets).each do |k|
      post "/#{k.gsub('_', '-')}/import-standard" => "#{k}#import_standard", :as => "import_standard_#{k}"
    end

    # special route for option suggestions
    get '/options/suggest' => 'options#suggest', :as => :suggest_options
  end

  # Special ODK routes. They are down here so that forms_path doesn't return the ODK variant.
  scope '(:locale)/:mode/:mission_id', :locale => /[a-z]{2}/, :mode => /m/, :mission_id => /[a-z][a-z0-9]*/ do
    get '/formList' => 'forms#index', :format => 'xml'
    get '/forms/:id' => 'forms#show', :format => 'xml', :as => :form_with_mission
    match '/submission' => 'responses#create', :format => 'xml'
  end

  root :to => 'welcome#index'
end
