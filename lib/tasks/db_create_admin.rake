# frozen_string_literal: true

namespace :db do
  desc "Create an admin user."
  task :create_admin, [:password] => :environment do |_t, args|
    if (begin
          configatron.webmaster_emails!
        rescue StandardError
          []
        end).empty?
      raise "Webmaster email must be configured in config/initializers/local_settings.rb " \
        "before admin can be generated."
    end

    u = User.new(login: "admin", name: "Admin", email: configatron.webmaster_emails.first, admin: true)

    admin_password = args[:password] || User.random_password
    u.password = u.password_confirmation = admin_password

    # need to turn off validation because there are no assignments and no password reset method
    u.save(validate: false)

    puts "Admin user created with username admin, password #{u.password}"
  end
end
