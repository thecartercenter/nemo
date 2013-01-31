namespace :db do
  desc "Create an admin user."
  task :create_admin => :environment do

    u = User.new(:login => "admin", :name => "Super User", :login => "super",
      :email => "webmaster@cceom.org", :admin => true)
    u.password = u.password_confirmation = 'changeme'
    
    # need to turn off validation because there are no assignments and no password reset method
    u.save(:validate => false)
  end
end