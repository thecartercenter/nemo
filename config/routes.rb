ELMO::Application.routes.draw do

  # redirects for ODK
  match("/missions/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/missions/:mission_compact_name/submission" => 'responses#create', :format => :xml)

  resources(:broadcasts){collection{post 'new_with_users'}}
  resources(:forms){member{post 'add_questions', 'remove_questions', 'update_ranks'; get 'publish', 'clone'}}
  resources(:form_types)
  resources(:markers)
  resources(:missions)
  resources(:options)
  resources(:option_sets)
  resources(:password_resets)
  resources(:permissions){collection{get 'no'}}
  resources(:questionings)
  resources(:questions){collection{get 'choose'}}
  resources(:responses)
  resources(:settings)
  resource(:user_session){collection{get 'logged_out'}}
  resources(:users){member{get 'login_instructions'}; collection{post 'export'}}
  resources(:user_batches)
  
  namespace(:report){resources(:reports)}

  # proxies for ajax
  match("proxies/:action", :controller => "proxies")
  
  # logout shortcut
  match("/logout" => "user_sessions#destroy")
  
  root(:to => "welcome#index")
  
end
