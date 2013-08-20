set :branch, "demo"
set :ping_url, "https://secure1.cceom.org"
set :user, 'cceom'
set :home_dir, '/home/cceom'
server 'cceom.org', :app, :web, :db, :primary => true