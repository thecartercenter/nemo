ELMO::Application.routes.draw do

  namespace :api, defaults: { format: :json } do
    api_version(:module => "v1", :path => {:value => "v1"}) do
      resources :missions, only: :index
    end
  end

  # redirects for ODK
  # shortened (/m)
  match("/m/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/m/:mission_compact_name/forms/:id" => 'forms#show', :format => :xml, :as => :form_with_mission)
  match("/m/:mission_compact_name/submission" => 'responses#create', :format => :xml)
  # full (/missions)
  match("/missions/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/missions/:mission_compact_name/forms/:id" => 'forms#show', :format => :xml)
  match("/missions/:mission_compact_name/submission" => 'responses#create', :format => :xml)

  # the routes in this scope /require/ admin mode
  scope "(:locale)(/:admin_mode)", :locale => /[a-z]{2}/, :admin_mode => /admin/ do
    resources(:missions)
  end

  # the routes in this scope are not valid in admin mode
  scope "(:locale)", :locale => /[a-z]{2}/ do
    resources(:broadcasts){collection{post 'new_with_users'}}
    resources(:password_resets)
    resources(:responses)
    resources(:sms, :only => [:index, :create])
    resources(:sms_tests)
    resource(:user_session){collection{get 'logged_out'}}

    namespace(:report) do
      resources(:reports)

      # need to list these all separately b/c rails is dumb sometimes
      resources(:question_answer_tally_reports, :controller => 'reports')
      resources(:grouped_tally_reports, :controller => 'reports')
      resources(:list_reports, :controller => 'reports')
      resources(:standard_form_reports, :controller => 'reports')
    end

    # special dashboard routes
    match('/info_window' => 'welcome#info_window', :as => :dashboard_info_window)
    match('/report_update/:id' => 'welcome#report_update')

    # login/logout shortcut
    match("/logged_out" => "user_sessions#logged_out", :as => :logged_out)
    match("/logout" => "user_sessions#destroy", :as => :logout)
    match("/login" => "user_sessions#new", :as => :login)
  end

  # the routes in this scope are admin mode optional
  scope "(:locale)(/:admin_mode)", :locale => /[a-z]{2}/ do

    # the rest of these routes can have admin mode or not
    resources(:forms){member{post *%w(add_questions remove_questions); put *%w(clone publish); get *%w(choose_questions)}}
    resources(:markers)
    resources(:questions)
    resources(:questionings)
    resources(:settings)
    resources(:users){member{get 'login_instructions'; get 'exit_admin_mode'}; collection{post 'export'}}
    resources(:user_batches)

    # looks nicer
    resources(:option_sets, :path => 'option-sets'){member{put 'clone'}}

    # for legacy support
    resources(:option_sets){member{put 'clone'}}


    # import routes for standardizeable objects
    %w(forms questions option_sets).each do |k|
      post("/#{k}/import_standard" => "#{k}#import_standard", :as => "import_standard_#{k}")
    end

    # special route for option suggestions
    match('/options/suggest' => 'options#suggest', :as => :suggest_options)

    root(:to => "welcome#index")
  end

  # need this so that '/' will work
  match('/' => "welcome#index")

  # proxies for ajax
  match("proxies/:action", :controller => "proxies")

end
