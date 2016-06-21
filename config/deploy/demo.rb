set :branch, 'demo'
set :ping_url, "https://elmo.sassafras.coop"
set :user, 'ubuntu'
set :home_dir, '/home/ubuntu'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/elmo"}

set :default_environment, {
  "PATH" => "$HOME/.rbenv/shims:$PATH"
}

server 'elmo.sassafras.coop', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "sudo service nginx #{command}"
    end
  end
end