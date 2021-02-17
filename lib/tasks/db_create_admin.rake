# frozen_string_literal: true

namespace :db do
  desc "Create an admin user."
  task :create_admin, [:password] => :environment do |_t, args|
    u = User.new(login: "admin", name: "Admin", email: Cnfg.webmaster_emails.first,
                 admin: true, pref_lang: "en")

    admin_password = args[:password] || User.random_password
    u.password = u.password_confirmation = admin_password

    # need to turn off validation because there are no assignments and no password reset method
    u.save(validate: false)

    puts "Admin user created with username admin, password #{u.password}"
  end
end
