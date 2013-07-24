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

  scope "(:locale)", :locale => /[a-z]{2}/ do
    resources(:broadcasts){collection{post 'new_with_users'}}
    resources(:forms){member{post *%w(add_questions remove_questions); get *%w(publish clone choose_questions)}}
    resources(:markers)
    resources(:missions)
    resources(:options, :only => [:create, :update]){collection{get 'suggest'}}
    resources(:option_sets)
    resources(:password_resets)
    resources(:questions)
    resources(:questionings)
    resources(:responses)
    resources(:settings)
    resources(:sms, :only => [:index, :create])
    resources(:sms_tests)
    resource(:user_session){collection{get 'logged_out'}}
    resources(:users){member{get 'login_instructions'}; collection{post 'export'}}
    resources(:user_batches)
  
    namespace(:report){resources(:reports)}

    match('/dashboard' => 'dashboard#show', :as => :dashboard)
    
    # login/logout shortcut
    match("/logged_out" => "user_sessions#logged_out", :as => :logged_out)
    match("/logout" => "user_sessions#destroy", :as => :logout)
    match("/login" => "user_sessions#new", :as => :login)

    root(:to => "welcome#index")
  end
  
  # proxies for ajax
  match("proxies/:action", :controller => "proxies")
end
