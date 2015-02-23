ELMO::Application.routes.draw do

  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)

  # proxies for ajax same-origin
  match 'proxies/:action', :controller => 'proxies'

  #####################################
  # Basic routes (neither mission nor admin mode)
  scope ':locale', :locale => /[a-z]{2}/, :defaults => {:mode => nil, :mission_name => nil} do

    # Routes requiring no user.
    resources :password_resets, :path => 'password-resets'
    resource :user_session, :path => 'user-session'
    get '/logged-out' => 'user_sessions#logged_out', :as => :logged_out
    get '/login' => 'user_sessions#new', :as => :login

    # Routes requiring user.
    match '/logout' => 'user_sessions#destroy', :as => :logout
    get '/route-tests' => 'route_tests#basic_mode' if Rails.env.development? || Rails.env.test?
    get '/unauthorized' => 'welcome#unauthorized', :as => :unauthorized

    # Routes with user or no user.
    root :to => 'welcome#index', :as => :basic_root
  end

  #####################################
  # Admin-mode-only routes
  scope ':locale/admin', :locale => /[a-z]{2}/, :defaults => {:mode => 'admin', :mission_name => nil} do
    resources :missions

    get '/route-tests' => 'route_tests#admin_mode' if Rails.env.development? || Rails.env.test?

    # for /en/admin
    root :to => 'welcome#index', :as => :admin_root
  end

  #####################################
  # Mission-mode-only routes
  scope ':locale/m/:mission_name', :locale => /[a-z]{2}/, :mission_name => /[a-z][a-z0-9]*/, :defaults => {:mode => 'm'} do
    resources(:broadcasts) do
      collection do
        post 'new_with_users', :path => 'new-with-users'
      end
    end
    resources :responses
    resources :sms, :only => [:index]
    resources :sms_tests, :path => 'sms-tests'

    resources :reports

    # need to list these all separately b/c rails is dumb sometimes
    resources :answer_tally_reports, :controller => 'reports'
    resources :response_tally_reports, :controller => 'reports'
    resources :list_reports, :controller => 'reports'
    resources :standard_form_reports, :controller => 'reports'

    # special dashboard routes
    match '/info-window' => 'welcome#info_window', :as => :dashboard_info_window
    get '/report-update/:id' => 'welcome#report_update'

    get '/route-tests' => 'route_tests#mission_mode' if Rails.env.development? || Rails.env.test?

    # for /en/m/mission123
    root :to => 'welcome#index', :as => :mission_root
  end

  #####################################
  # Admin mode OR mission mode routes
  scope ':locale/:mode(/:mission_name)', :locale => /[a-z]{2}/, :mode => /m|admin/, :mission_name => /[a-z][a-z0-9]*/ do

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
    resources :questionings do
      collection do
        get 'condition_form', :path => 'condition-form'
      end
    end
    resources :settings
    resources :user_batches, :path => 'user-batches'
    resources :groups

    resources :option_sets, :path => 'option-sets' do
      member do
        get 'options_for_node', :path => 'options-for-node'
        put 'clone'
      end
    end

    # import routes for standardizeable objects
    %w(forms questions option_sets).each do |k|
      post "/#{k.gsub('_', '-')}/import-standard" => "#{k}#import_standard", :as => "import_standard_#{k}"
    end

    # special routes for tokeninput suggestions
    get '/options/suggest' => 'options#suggest', :as => :suggest_options
    get '/tags/suggest' => 'tags#suggest', :as => :suggest_tags
  end

  #####################################
  # Any mode routes
  scope ':locale(/:mode)(/:mission_name)', :locale => /[a-z]{2}/, :mode => /m|admin/, :mission_name => /[a-z][a-z0-9]*/ do
    resources :users do
      member do
        get 'login_instructions', :path => 'login-instructions'
        put 'regenerate_key'
      end
      post 'export', :on => :collection
    end
  end

  # Special SMS and ODK routes. No locale.
  scope '/m/:mission_name', :mission_name => /[a-z][a-z0-9]*/, :defaults => {:mode => 'm'} do
    resources :sms, :only => [:create]
    get '/sms/submit' => 'sms#create'

    # ODK routes. They are down here so that forms_path doesn't return the ODK variant.
    get '/formList' => 'forms#index', :format => 'xml', :as => :odk_form_list, :direct_auth => true
    get '/forms/:id' => 'forms#show', :format => 'xml', :as => :odk_form, :direct_auth => true
    get '/forms/:id/manifest' => 'forms#odk_manifest', :format => 'xml', :direct_auth => true, :as => :odk_form_manifest
    get '/forms/:id/itemsets' => 'forms#odk_itemsets', :format => 'csv', :direct_auth => true, :as => :odk_form_itemsets
    match '/submission' => 'responses#create', :direct_auth => true, :format => 'xml'

    # Unauthenticated submissions
    match '/noauth/submission' => 'responses#create', :format => :xml, :no_auth => true
  end

  # API routes.
  namespace :api, defaults: { format: :json } do
    api_version :module => 'v1', :path => {:value => 'v1'} do
      scope '/m/:mission_name', :mission_name => /[a-z][a-z0-9]*/, :defaults => {:mode => 'm'} do
        resources :forms, only: [:index, :show]
        resources :responses, only: :index
        resources :answers, only: :index
      end
    end
  end

  root :to => redirect("/#{I18n.default_locale}")
end
