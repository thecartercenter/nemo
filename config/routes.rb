CommandCenter::Application.routes.draw do
  resources(:broadcasts){collection{post 'new_with_users'}}
  resources(:forms){member{post 'add_questions', 'remove_questions', 'update_ranks'; get 'publish', 'clone'}}
  resources(:form_types)
  resources(:languages)
  resources(:markers)
  resources(:options)
  resources(:option_sets)
  resources(:password_resets)
  resources(:permissions){collection{get 'no'}}
  resources(:questionings)
  resources(:questions){collection{get 'choose'}}
  resources(:responses)
  resources(:search_searches){member{get 'clear'}; collection{get 'start'}}
  resources(:settings){collection{post 'update_all'}}
  resource(:user_session){collection{get 'logged_out'}}
  resources(:users){member{get 'login_instructions'}; collection{post 'export'}}
  resources(:user_batches)
  
  namespace(:report){resources(:reports)}

  root(:to => "welcome#index")
  
  # redirects for ODK
  match("/formList" => 'forms#index', :format => :xml)
  match("/submission" => 'responses#create', :format => :xml)
end
