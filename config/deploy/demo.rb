set :branch, 'staging'
set :ping_url, "https://elmo.sassafrastech.com"
set :user, 'tomsmyth'
set :home_dir, '/home/tomsmyth'
server 'tomsmyth.ca', :app, :web, :db, :primary => true