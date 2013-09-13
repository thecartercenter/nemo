ELMO::Application.routes.draw do

  # redirects for ODK
  # shortened (/m)
  match("/m/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/m/:mission_compact_name/forms/:id" => 'forms#show', :format => :xml, :as => :form_with_mission)
  match("/m/:mission_compact_name/submission" => 'responses#create', :format => :xml)
  # full (/missions)
  match("/missions/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/missions/:mission_compact_name/forms/:id" => 'forms#show', :format => :xml)
  match("/missions/:mission_compact_name/submission" => 'responses#create', :format => :xml)

  scope "(:locale)(/:admin_mode)", :locale => /[a-z]{2}/ do
    resources(:broadcasts){collection{post 'new_with_users'}}
    resources(:forms){member{post *%w(add_questions remove_questions); get *%w(publish clone choose_questions)}}
    resources(:markers)
    resources(:missions)
    resources(:option_sets)
    resources(:password_resets)
    resources(:questions)
    resources(:questionings)
    resources(:responses)
    resources(:settings)
    resources(:sms, :only => [:index, :create])
    resources(:sms_tests)
    resource(:user_session){collection{get 'logged_out'}}
    resources(:users){member{get 'login_instructions'; get 'exit_admin_mode'}; collection{post 'export'}}
    resources(:user_batches)
  
    namespace(:report) do
      resources(:reports)
      resources(:question_answer_tally_reports, :controller => 'reports')
      resources(:grouped_tally_reports, :controller => 'reports')
      resources(:list_reports, :controller => 'reports')
    end

    # import routes for standardizeable objects
    %w(forms questions option_sets).each do |k|
      post("/#{k}/import_standard" => "#{k}#import_standard", :as => "import_standard_#{k}")
    end

    match('/options/suggest' => 'options#suggest', :as => :suggest_options)

    match('/dashboard' => 'dashboard#show', :as => :dashboard)
    match('/dashboard/info_window' => 'dashboard#info_window', :as => :dashboard_info_window)
    match('/dashboard/report_pane/:id' => 'dashboard#report_pane')
    
    # login/logout shortcut
    match("/logged_out" => "user_sessions#logged_out", :as => :logged_out)
    match("/logout" => "user_sessions#destroy", :as => :logout)
    match("/login" => "user_sessions#new", :as => :login)

    root(:to => "welcome#index")
  end

  # need this so that '/' will work
  match('/' => "welcome#index")

  # proxies for ajax
  match("proxies/:action", :controller => "proxies")
end
