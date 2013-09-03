namespace :db do
  desc "Create an admin user."
  task :create_admin => :environment do

    u = User.new(:login => "admin", :name => "Admin", :login => "admin",
      :email => "webmaster@cceom.org", :admin => true, :pref_lang => "en")
    u.password = u.password_confirmation = 'temptemp'
    
    # need to turn off validation because there are no assignments and no password reset method
    u.save(:validate => false)
  end
end