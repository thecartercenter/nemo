set :branch, 'demo'
set :ping_url, "https://elmo.sassafras.coop"
set :user, 'tomsmyth'
set :home_dir, '/home/tomsmyth'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/webapps/rails/elmo_demo"}
set(:bundle_dir) {"#{home_dir}/webapps/rails/gems"}
set :default_environment, {
  "PATH" => "$HOME/bin:$HOME/webapps/rails/bin:$PATH",
  "GEM_HOME" => "$HOME/webapps/rails/gems"
}

server 'tomsmyth.ca', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "#{home_dir}/webapps/rails/bin/#{command}"
    end
  end
end