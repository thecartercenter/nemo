set :branch, 'api_develop'
set :ping_url, "https://elmo-api.sassafras.coop"
set :user, 'tomsmyth'
set :home_dir, '/home/tomsmyth'
server 'tomsmyth.ca', :app, :web, :db, :primary => true