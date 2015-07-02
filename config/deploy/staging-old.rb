set :branch, 'staging_old'
set :ping_url, "https://secure1.cceom.org"
set :user, 'cceom'
set :home_dir, '/home/cceom'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/webapps/rails2/elmo_staging"}
set :bundle_dir, "$HOME/webapps/rails2/gems"
set :default_environment, {
  "PATH" => "$PATH:$HOME/bin:$HOME/webapps/rails2/bin",
  "GEM_HOME" => "$HOME/webapps/rails2/gems"
}

server 'cceom.org', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "#{home_dir}/webapps/rails2/bin/#{command}"
    end
  end
end
