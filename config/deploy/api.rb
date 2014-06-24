set :branch, 'api_develop'
set :ping_url, "http://elmo-api.sassafras.coop"
set :user, 'tomsmyth'
set :home_dir, '/home/tomsmyth'
server 'sassafras.coop', :app, :web, :db, :primary => true