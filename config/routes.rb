ELMO::Application.routes.draw do

  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails)

  # proxies for ajax same-origin
  get "proxies/:action", controller: "proxies"

  # Special shortcut for simulating login in feature specs.
  get "test-login" => "user_sessions#test_login" if Rails.env.test?

  #####################################
  # Basic routes (neither mission nor admin mode)
  scope ":locale", locale: /[a-z]{2}/, defaults: {mode: nil, mission_name: nil} do

    # Routes requiring no user.
    resources :password_resets, path: "password-resets"
    resource :user_session, path: "user-session"
    get "/logged-out" => "user_sessions#logged_out", as: :logged_out
    get "/login" => "user_sessions#new", as: :login

    # Routes requiring user.
    match "/logout" => "user_sessions#destroy", as: :logout, via: [:delete]
    get "/route-tests" => "route_tests#basic_mode" if Rails.env.development? || Rails.env.test?
    get "/unauthorized" => "welcome#unauthorized", as: :unauthorized

    get "/confirm-login" => "user_sessions#login_confirmation", defaults: { confirm: true }, as: :new_login_confirmation
    post "/confirm-login" => "user_sessions#process_login_confirmation", defaults: { confirm: true }, as: :login_confirmation

    resources :operations, only: %i(index show destroy) do
      collection do
        post "clear"
      end
    end

    # Routes with user or no user.
    root to: "welcome#index", as: :basic_root
  end

  #####################################
  # Admin-mode-only routes
  scope ":locale/admin", locale: /[a-z]{2}/, defaults: {mode: "admin", mission_name: nil} do
    resources :missions

    get "/route-tests" => "route_tests#admin_mode" if Rails.env.development? || Rails.env.test?

    # for /en/admin
    root to: "welcome#index", as: :admin_root
  end

  #####################################
  # Mission-mode-only routes
  scope ":locale/m/:mission_name", locale: /[a-z]{2}/, mission_name: /[a-z][a-z0-9]*/, defaults: {mode: "m"} do
    resources(:broadcasts) do
      collection do
        get "possible_recipients", path: "possible-recipients"
        post "new_with_users", path: "new-with-users"
      end
    end
    resources :responses do
      %i(new member).each do |type|
        get "possible_submitters", path: "possible-submitters", on: type
      end
    end
    resources :sms, only: [:index] do
      collection do
        get "incoming_numbers", path: "incoming-numbers", defaults: { format: "csv" }
      end
    end

    resources :sms_tests, path: "sms-tests"

    resources :reports do
      member do
        get "data"
      end
    end

    namespace :media, type: /audios|images|videos/ do
      get ":type/:id(/:style)" => "objects#show", defaults: { style: "original" }
      post ":type" => "objects#create", as: :create
      delete ":type/:id" => "objects#delete", as: :delete
    end

    # need to list these all separately b/c rails is dumb sometimes
    resources :answer_tally_reports, controller: "reports"
    resources :response_tally_reports, controller: "reports"
    resources :list_reports, controller: "reports"
    resources :standard_form_reports, controller: "reports"

    # special dashboard routes
    get "/info-window" => "welcome#info_window", as: :dashboard_info_window
    get "/route-tests" => "route_tests#mission_mode" if Rails.env.development? || Rails.env.test?

    # for /en/m/mission123
    root to: "welcome#index", as: :mission_root
  end

  #####################################
  # Admin mode OR mission mode routes
  scope ":locale/:mode(/:mission_name)", locale: /[a-z]{2}/, mode: /m|admin/, mission_name: /[a-z][a-z0-9]*/ do

    # the rest of these routes can have admin mode or not
    resources :forms do
      member do
        post "add_questions", path: "add-questions"
        post "remove_questions", path: "remove-questions"
        put "clone"
        put "publish"
        get "choose_questions", path: "choose-questions"
        get "sms_guide", path: "sms-guide"
      end
    end
    resources :markers
    resources :questions
    resources :questionings do
      collection do
        get "condition_form", path: "condition-form"
      end
    end

    resources :qing_groups, path: "qing-groups", except: :index
    resources :settings do
      member do
        post "regenerate_override_code"
        post "regenerate_incoming_sms_token"
      end
      collection do
        get "using_incoming_sms_token_message"
      end
    end
    resources :user_batches, path: "user-batches" do
      collection do
        get "example_spreadsheet", path: "example-user-batch", defaults: { format: "xslx" }
      end
    end

    resources :user_groups do
      post "add_users"
      post "remove_users"
      collection do
        get "possible_groups", path: "possible-groups"
      end
    end

    resources :form_items, path: "form-items", only: [:update]

    resources :option_sets, path: "option-sets" do
      member do
        get "child_nodes", path: "child-nodes"
        put "clone"
        get "export", defaults: { format: "xlsx" }
      end
    end

    resource :option_set_imports, path: "option-set-imports", only: [:new, :create] do
      collection do
        get "example_spreadsheet", path: "example-option-set", defaults: { format: "xlsx" }
      end
    end

    # import routes for standardizeable objects
    %w(forms questions option_sets).each do |k|
      post "/#{k.gsub('_', '-')}/import-standard" => "#{k}#import_standard", as: "import_standard_#{k}"
    end

    # special routes for tokeninput suggestions
    get "/options/suggest" => "options#suggest", as: :suggest_options
    get "/tags/suggest" => "tags#suggest", as: :suggest_tags
  end

  #####################################
  # Any mode routes
  scope ":locale(/:mode)(/:mission_name)", locale: /[a-z]{2}/, mode: /m|admin/, mission_name: /[a-z][a-z0-9]*/ do
    resources :users do
      member do
        get "login_instructions", path: "login-instructions"
        post "regenerate_api_key"
        post "regenerate_sms_auth_code"
      end
      collection do
        post "export"
        post "bulk_destroy", path: "bulk-destroy"
      end
    end
  end

  # Special SMS routes. No locale.
  def sms_submission_route(as:)
    match "/sms/submit/:token" => "sms#create", token: /[0-9a-f]{32}/, via: [:get, :post], as: as
  end
  scope "/m/:mission_name", mission_name: /[a-z][a-z0-9]*/, defaults: { mode: "m"} do
    sms_submission_route(as: :mission_sms_submission)
  end
  sms_submission_route(as: :missionless_sms_submission)

  # Special ODK routes. No locale. They are down here so that forms_path doesn"t return the ODK variant.
  #
  # NOTE: Brute-force login protection happens in the rack-attack middleware,
  # which executes before routing. Be sure that all paths marked with
  # :direct_auth => true are also matched by the direct_auth? method in
  # config/initializers/rack-attack.rb
  scope "/m/:mission_name", mission_name: /[a-z][a-z0-9]*/, defaults: { mode: "m", direct_auth: "basic" } do
    get "/formList" => "forms#index", as: :odk_form_list, defaults: {format: "xml"}
    get "/forms/:id" => "forms#show", as: :odk_form, defaults: {format: "xml"}
    get "/forms/:id/manifest" => "forms#odk_manifest", as: :odk_form_manifest, defaults: {format: "xml"}
    get "/forms/:id/itemsets" => "forms#odk_itemsets", as: :odk_form_itemsets, defaults: {format: "csv"}

    match "/submission" => "responses#odk_headers", via: [:head, :get], defaults: { format: "xml" }
    post "/submission" => "responses#create", defaults: { format: "xml" }

    # Unauthenticated submissions
    match "/noauth/submission" => "responses#odk_headers", via: [:head, :get], defaults: { format: "xml", direct_auth: "none" }
    post "/noauth/submission" => "responses#create", defaults: { format: "xml", direct_auth: "none" }
  end

  # API routes.
  namespace :api, defaults: { format: :json } do
    api_version module: "v1", path: { value: "v1"} do
      scope "/m/:mission_name", mission_name: /[a-z][a-z0-9]*/, defaults: {mode: "m"} do
        resources :forms, only: [:index, :show]
        resources :responses, only: :index
        resources :answers, only: :index
      end
    end
  end

  root to: redirect("/#{I18n.default_locale}")
end
