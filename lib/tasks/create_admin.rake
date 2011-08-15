namespace :db do
  desc "Create an admin user." 
  task :create_admin => :environment do

    u = User.new(:login => "admin", :first_name => "Super", :last_name => "User", 
      :email => "webmaster@cceom.org", :role_id => Role.find(:first, :order => "level").id,
      :active => true, :language_id => Language.english.id)
    u.password = u.password_confirmation = 'tickleME'
    u.save
  end
end