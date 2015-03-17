set :branch, 'demo'
set :ping_url, "https://elmo.sassafras.coop"
set :user, 'tomsmyth'
set :home_dir, '/home/tomsmyth'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/webapps/rails2/#{application}_#{stage}"}
set :default_environment, {
  "PATH" => "$PATH:$HOME/bin:$HOME/webapps/rails2/bin",
  "GEM_HOME" => "$HOME/webapps/rails2/gems"
}

server 'tomsmyth.ca', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "#{home_dir}/webapps/rails2/bin/#{command}"
    end
  end
end