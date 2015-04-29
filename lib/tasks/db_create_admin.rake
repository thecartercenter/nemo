namespace :db do
  desc "Create an admin user."
  task :create_admin => :environment do

    if (configatron.webmaster_emails! rescue []).empty?
      raise 'Webmaster email must be configured in config/initializers/local_settings.rb before admin can be generated.'
    end

    u = User.new(login: "admin", name: "Admin", login: "admin", email: configatron.webmaster_emails.first, admin: true)
    u.password = u.password_confirmation = User.random_password

    # need to turn off validation because there are no assignments and no password reset method
    u.save(validate: false)

    puts "Admin user created with username admin, password #{u.password}"
  end
end