set :branch, 'staging'
set :ping_url, "https://secure1.cceom.org"
set :user, 'cceom'
set :home_dir, '/home/cceom'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/webapps/elmo_rails/#{stage}"}
set :default_environment, {
  "PATH" => "$PATH:$HOME/bin:$HOME/webapps/elmo_rails/bin",
  "GEM_HOME" => "$HOME/webapps/elmo_rails/gems"
}

server 'staging.getelmo.org', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "#{home_dir}/webapps/elmo_rails/bin/#{command}"
    end
  end
end
