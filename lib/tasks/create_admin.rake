namespace :db do
  desc "Create an admin user." 
  task :create_admin => :environment do

    u = User.new(:login => "admin", :name => "Super User", :login => "super",
      :email => "webmaster@cceom.org", :admin => true, :language_id => Language.english.id)
    u.password = u.password_confirmation = 'changeme'
    u.save
  end
end