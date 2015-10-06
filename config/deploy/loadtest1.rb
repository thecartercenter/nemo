set :branch, 'develop'
set :ping_url, 'https://loadtest1.getelmo.org'
set :user, 'elmo'
set :home_dir, '/home/elmo'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/#{application}"}

# Path to PEM file on developer local machine.
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/loadtest1.getelmo.org.pem"]

# Default environment on server.
set :default_environment, {
  "PATH" => "$HOME/.rbenv/shims:$PATH"
}

server 'loadtest1.getelmo.org', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "sudo service nginx #{command}"
    end
  end
end
