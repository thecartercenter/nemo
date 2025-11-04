# frozen_string_literal: true

# For details on the DSL available within this file,
# see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  # Special shortcut for simulating login in feature specs.
  get("test-login", to: "user_sessions#test_login") if Rails.env.test?

  # For uptime checking
  get "ping", to: "ping#show"

  #####################################
  # Basic routes (neither mission nor admin mode)
  scope ":locale", locale: /[a-z]{2}/, defaults: {mode: nil, mission_name: nil} do
    # Routes requiring no user.
    resources :password_resets, path: "password-resets", only: %i[new edit create update]
    resource :user_session, path: "user-session", only: %i[new create destroy]
    get "/logged-out", to: "user_sessions#logged_out", as: :logged_out
    get "/login", to: "user_sessions#new", as: :login

    # Routes requiring user.
    delete "/logout", to: "user_sessions#destroy", as: :logout
    get("/route-tests", to: "route_tests#basic_mode") if Rails.env.local?
    get "/unauthorized", to: "welcome#unauthorized", as: :unauthorized
    
    # Notifications
    resources :notifications, only: %i[index show destroy] do
      collection do
        patch "mark_all_as_read"
        delete "destroy_all"
        get "unread_count"
      end
      member do
        patch "mark_as_read"
      end
    end

    # Analytics
    resources :analytics, only: [] do
      collection do
        get "dashboard"
        get "response_trends"
        get "form_performance"
        get "geographic_data"
      end
    end

    # Data Exports
    resources :exports, only: [:new, :create] do
      collection do
        get "status"
      end
      member do
        get "download/:filename", action: "download", as: "download"
      end
    end

    # Audit Logs
    resources :audit_logs, only: [:index, :show] do
      collection do
        get "export"
        get "statistics"
      end
    end

    # Form Templates
    resources :form_templates do
      member do
        get "use"
        post "create_from_template"
      end
      collection do
        post "create_from_form"
      end
    end

    # Validation Rules
    resources :validation_rules do
      member do
        patch "toggle"
      end
      collection do
        get "test"
        get "get_questions"
      end
    end

    # AI Validation Rules
    resources :ai_validation_rules, path: "ai-validation-rules", controller: "ai_validation" do
      member do
        patch "toggle_active"
        post "test_rule"
      end
      collection do
        post "validate_response"
        post "validate_batch"
        get "report"
        get "suggestions"
        post "create_from_suggestion"
      end
    end

    # Comments and Annotations
    resources :responses do
      resources :comments do
        member do
          patch "resolve"
          patch "unresolve"
        end
      end
      resources :annotations
    end

    # Mobile API
    namespace :api do
      namespace :v1 do
        # Authentication
        post "auth/login", to: "auth#login"
        post "auth/logout", to: "auth#logout"
        post "auth/register", to: "auth#register"
        get "auth/profile", to: "auth#profile"
        patch "auth/profile", to: "auth#update_profile"
        patch "auth/change_password", to: "auth#change_password"
        post "auth/forgot_password", to: "auth#forgot_password"
        post "auth/reset_password", to: "auth#reset_password"
        get "auth/missions", to: "auth#missions"
        patch "auth/switch_mission", to: "auth#switch_mission"
        
        # Resources
        resources :forms do
          member do
            patch "publish"
            patch "unpublish"
          end
        end
        
        resources :responses do
          member do
            patch "submit"
            patch "mark_incomplete"
          end
        end
        
        resources :notifications do
          collection do
            patch "mark_all_as_read"
            get "unread_count"
            delete "destroy_all"
          end
        end
      end
    end

    # Data Backups
    resources :backups do
      member do
        get "download"
        post "restore"
      end
      collection do
        post "cleanup_old"
      end
    end

    # Webhooks
    resources :webhooks do
      member do
        post "test"
        get "deliveries"
      end
    end

    # Custom Dashboards
    resources :custom_dashboards do
      member do
        post "duplicate"
        get "export"
        get "widgets"
        post "add_widget"
        delete "remove_widget"
        patch "reorder_widgets"
      end
      collection do
        post "import"
      end
    end

    # AI Validation
    resources :ai_validation_rules, path: "ai-validation-rules" do
      member do
        patch "toggle_active"
        post "test_rule"
      end
      collection do
        post "validate_response"
        post "validate_batch"
        get "report"
        get "suggestions"
        post "create_from_suggestion"
      end
    end

    # Workflows
    resources :workflows do
      member do
        patch "activate"
        patch "deactivate"
        post "create_instance"
      end
      collection do
        get "my_approvals"
        get "my_workflows"
      end
    end

    # Workflow Instances
    resources :workflow_instances, only: [] do
      member do
        post "approve"
        post "reject"
        post "cancel"
        get "details"
      end
    end

    # Advanced Search
    get "search", to: "search#index"
    get "search/suggestions", to: "search#suggestions"
    get "search/advanced", to: "search#advanced"
    get "search/results", to: "search#results"

    get "/confirm-login", to: "user_sessions#login_confirmation",
      defaults: {confirm: true}, as: :new_login_confirmation
    post "/confirm-login", to: "user_sessions#process_login_confirmation",
      defaults: {confirm: true}, as: :login_confirmation

    # Routes with user or no user.
    root to: "welcome#index", as: :basic_root
  end

  #####################################
  # Admin-mode-only routes
  scope ":locale/admin", locale: /[a-z]{2}/, defaults: {mode: "admin", mission_name: nil} do
    resources :missions

    get("/route-tests", to: "route_tests#admin_mode") if Rails.env.local?

    # for /en/admin
    root to: "welcome#index", as: :admin_root
  end

  #####################################
  # Mission-mode-only routes
  scope ":locale/m/:mission_name", locale: /[a-z]{2}/, mission_name: /[a-z][a-z0-9]*/,
    defaults: {mode: "m"} do
    mount(OData::Engine, at: OData::BASE_PATH, defaults: {direct_auth: "basic"})

    # OData debugging endpoints to allow serving static text.
    if Rails.env.development?
      get(OData::STUBS_PATH, to: "stubbed_o_data#root")
      get("#{OData::STUBS_PATH}/$metadata", to: "stubbed_o_data#metadata")
      get("#{OData::STUBS_PATH}/:id", to: "stubbed_o_data#resource")
    end

    # Regular form resources are defined under the admin-or-mission section.
    resources :forms, only: [] do
      member do
        patch "pause"
        patch "go-live", as: "go_live"
        patch "return-to-draft", as: "return_to_draft"
        patch "increment_version"
        patch "re_cache"
      end
    end

    resources :broadcasts, only: %i[index show new create] do
      collection do
        get "possible-recipients", as: "possible_recipients", action: "possible_recipients"
        post "new-with-users", as: "new_with_users", action: "new_with_users"
      end
    end

    resources :responses do
      collection do
        post "bulk-destroy", as: "bulk_destroy", action: "bulk_destroy"

        get "possible-submitters", as: "possible_submitters", action: "possible_submitters"
        get "possible-reviewers", as: "possible_reviewers", action: "possible_reviewers"
      end
    end

    resources :sms, only: [:index] do
      collection do
        get "incoming-numbers", as: "incoming_numbers", action: "incoming_numbers", defaults: {format: "csv"}
      end
    end

    resources :sms_tests, path: "sms-tests", only: %i[new create]

    resources :reports do
      member do
        get "data"
      end
    end

    namespace :media, type: /audios|images|videos/ do
      resources :objects, path: ":type", only: %i[show create destroy]
    end

    # need to list these all separately b/c rails is dumb sometimes
    resources :answer_tally_reports, controller: "reports"
    resources :response_tally_reports, controller: "reports"
    resources :list_reports, controller: "reports"
    resources :standard_form_reports, controller: "reports"

    # special responses routes
    get "/media-size", to: "responses#media_size", action: "media_size"

    # special dashboard routes
    get "/dashboard/report", to: "dashboard#report", as: :dashboard_report
    get "/dashboard/info-window", to: "dashboard#info_window", as: :dashboard_info_window
    get "/route-tests", to: "route_tests#mission_mode" if Rails.env.local?

    # for /en/m/mission123
    root to: "dashboard#index", as: :mission_root
  end

  #####################################
  # Admin mode OR mission mode routes
  scope ":locale/:mode(/:mission_name)", locale: /[a-z]{2}/, mode: /m|admin/,
    mission_name: /[a-z][a-z0-9]*/ do
    # the rest of these routes can have admin mode or not
    resources :forms, constraints: ->(req) { req.format == :html } do
      collection do
        get "export_all"
      end

      member do
        post "add-questions", as: "add_questions", action: "add_questions"
        put "clone"
        get "choose-questions", as: "choose_questions", action: "choose_questions"
        get "sms-guide", as: "sms_guide", action: "sms_guide"
        get "export"
        get "export_xml"
        get "export_xls"
      end
    end

    resources :operations, only: %i[index show destroy] do
      collection do
        post "clear"
      end
      member do
        get "download"
      end
    end

    resources :questions do
      collection do
        post "bulk-destroy", as: "bulk_destroy", action: "bulk_destroy"
        post "export", defaults: {format: "csv"}
      end
    end

    resources :questionings, only: %i[show edit create update destroy]
    resources :qing_groups, path: "qing-groups", only: %i[new edit create show update destroy]

    resources :settings, only: %i[index update] do
      member do
        patch "regenerate_override_code"
        patch "regenerate_incoming_sms_token"
      end
      collection do
        get "using_incoming_sms_token_message"
      end
    end

    resources :user_imports, path: "user-imports", only: %i[new create] do
      collection do
        get :template
        post :upload
      end
    end

    resources :user_groups, only: %i[index edit update create destroy] do
      post "add_users"
      post "remove_users"
      collection do
        get "possible-groups", as: "possible_groups", action: "possible_groups"
      end
    end

    resources :form_items, path: "form-items", only: [:update]

    resources :option_sets, path: "option-sets" do
      member do
        get "child-nodes", as: "child-nodes", action: "child_nodes"
        put "clone"
        get "export", defaults: {format: "csv"}
      end
    end

    resources :option_set_imports, path: "option-set-imports", only: %i[new create] do
      collection do
        get :template_multilevel
        get :template_translations
        post :upload
      end
    end

    resources :question_imports, path: "question-imports", only: %i[new create] do
      collection do
        get :template
        post :upload
      end
    end

    # import routes for standardizeable objects
    %w[forms questions option_sets].each do |k|
      post "/#{k.tr('_', '-')}/import-standard", to: "#{k}#import_standard", as: "import_standard_#{k}"
    end

    # Non-RESTful, JSON only controllers for React
    get "/condition-form-data/base", to: "condition_form_data#base"
    get "/condition-form-data/option-path", to: "condition_form_data#option_path"
    get "/filter-data/qings", to: "filter_data#qings"

    # special routes for tokeninput suggestions
    get "/tags/suggest", to: "tags#suggest", as: :suggest_tags
  end

  #####################################
  # Any mode routes
  scope ":locale(/:mode)(/:mission_name)", locale: /[a-z]{2}/, mode: /m|admin/,
    mission_name: /[a-z][a-z0-9]*/ do
    resources :users do
      member do
        get "login-instructions", as: "login_instructions", action: "login_instructions"
        patch "regenerate_api_key"
        patch "regenerate_sms_auth_code"
      end
      collection do
        post "export"
        post "bulk-destroy", as: "bulk_destroy", action: "bulk_destroy"
      end
    end
  end

  # Special SMS routes. No locale.
  def sms_submission_route(as:) # rubocop:disable Naming/MethodParameterName
    match("/sms/submit/:token", to: "sms#create", token: /[0-9a-f]{32}/, via: %i[get post], as: as)
  end
  scope "/m/:mission_name", mission_name: /[a-z][a-z0-9]*/, defaults: {mode: "m"} do
    sms_submission_route(as: :mission_sms_submission)
  end
  sms_submission_route(as: :missionless_sms_submission)

  # Special ODK routes. No locale. They are down here so that forms_path doesn't return the ODK variant.
  #
  # NOTE: Brute-force login protection happens in the rack-attack middleware,
  # which executes before routing. Be sure that all paths marked with
  # `direct_auth: true` are also matched by the direct_auth? method in
  # config/initializers/rack-attack.rb
  scope "(/:locale)/m/:mission_name", mission_name: /[a-z][a-z0-9]*/,
    defaults: {mode: "m", direct_auth: "basic"},
    constraints: ->(r) { %w[xml csv].include?(r.format) } do
    get "/formList", to: "forms#index", as: :odk_form_list, defaults: {format: "xml"}
    get "/forms/:id", to: "forms#show", as: :odk_form, defaults: {format: "xml"}
    get "/forms/:id/manifest", to: "forms#odk_manifest", as: :odk_form_manifest, defaults: {format: "xml"}
    get "/forms/:id/itemsets", to: "forms#odk_itemsets", as: :odk_form_itemsets, defaults: {format: "csv"}

    match "/submission", to: "responses#odk_headers", via: %i[head get], defaults: {format: "xml"}
    post "/submission", to: "responses#create", defaults: {format: "xml"}
    put "/submission/:id", to: "responses#enketo_update", defaults: {format: "xml"}
  end

  root to: redirect("/#{I18n.default_locale}")
end
