set :branch, 'nemo-hrdef'
set :ping_url, 'https://hrdef.getnemo.org'
set :user, 'ubuntu'
set :home_dir, '/home/ubuntu'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/#{application}"}

# Default environment on server.
set :default_environment, {
  "PATH" => "$HOME/.rbenv/shims:$PATH"
}

server 'hrdef.getnemo.org', :app, :web, :db, primary: true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "sudo service nginx #{command}"
    end
  end
end
