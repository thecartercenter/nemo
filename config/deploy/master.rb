set :branch, "master"
set :ping_url, "https://cceom.org"
set :user, 'cceom'
set :home_dir, '/home/cceom'
server 'cceom.org', :app, :web, :db, :primary => true