set :branch, 'production'
set :ping_url, "https://secure1.cceom.org"
set :user, 'ubuntu'
set :home_dir, '/home/ubuntu'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/elmo"}

server 'secure1.cceom.org', :app, :web, :db, primary: true

# Default environment on server.
set :default_environment, {
  "PATH" => "$HOME/.rbenv/shims:$PATH"
}

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "sudo service nginx #{command}"
    end
  end
end
