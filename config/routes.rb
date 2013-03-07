ELMO::Application.routes.draw do

  # redirects for ODK
  match("/missions/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/m/:mission_compact_name/formList" => 'forms#index', :format => :xml)
  match("/missions/:mission_compact_name/submission" => 'responses#create', :format => :xml)
  match("/m/:mission_compact_name/submission" => 'responses#create', :format => :xml)

  resources(:broadcasts){collection{post 'new_with_users'}}
  resources(:forms){member{post *%w(add_questions remove_questions update_ranks); get *%w(publish clone choose_questions)}}
  resources(:form_types)
  resources(:markers)
  resources(:missions)
  resources(:options)
  resources(:option_sets)
  resources(:password_resets)
  resources(:permissions){collection{get 'no'}}
  resources(:questionings)
  resources(:responses)
  resources(:settings)
  resource(:user_session){collection{get 'logged_out'}}
  resources(:users){member{get 'login_instructions'}; collection{post 'export'}}
  resources(:user_batches)
  
  namespace(:report){resources(:reports)}
  
  # proxies for ajax
  match("proxies/:action", :controller => "proxies")
  
  # login/logout shortcut
  match("/logged_out" => "user_sessions#logged_out", :as => :logged_out)
  match("/logout" => "user_sessions#destroy", :as => :logout)
  match("/login" => "user_sessions#new", :as => :login)
  
  root(:to => "welcome#index")
  
end
