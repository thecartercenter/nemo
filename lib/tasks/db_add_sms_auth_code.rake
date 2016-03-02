namespace :db do
  desc "Add SMS auth codes to users"
  task :add_sms_auth_codes => :environment do
    User.find_each do |user|
      auth_code = Random.alphanum(4)
      user.update_column(:sms_auth_code, auth_code)
    end
  end
end
