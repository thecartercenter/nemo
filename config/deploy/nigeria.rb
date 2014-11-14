set :branch, 'master'
set :ping_url, 'https://cceom.org'
set :user, 'ubuntu'
set :home_dir, '/home/ubuntu'
set :use_sudo, false
set(:deploy_to) {"#{home_dir}/#{application}_#{stage}"}
ssh_options[:keys] = %w(/Users/tomsmyth/.ssh/aggie-ec2-key.pem)
set :default_environment, {
  "PATH" => "$HOME/.rbenv/shims:$PATH"
}


server 'ec2-54-86-203-4.compute-1.amazonaws.com', :app, :web, :db, :primary => true

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} server"
    task command, roles: :app, except: {no_release: true} do
      run "sudo service nginx #{command}"
    end
  end
end
