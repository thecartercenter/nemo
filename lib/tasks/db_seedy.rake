namespace :db do
  desc "Seed the current environment's database." 
  task :seedy => :environment do
    ActiveRecord::Base.transaction do

      # generate all permanent, mandatory seeds
      to_seed = [Language, Role, Settable, FormType, QuestionType, PlaceType, Report::ResponseAttribute, Report::Aggregation]
      to_seed.each{|c| c.generate}
      
      # generate initial superuser
      unless User.find_by_role_id(Role.highest.id)
        User.ignore_blank_passwords = true
        find_or_create(User, :login, :login => "super", :name => "Super User", :login => "super",
          :email => "webmaster@cceom.org", :role => Role.highest, :active => true, 
          :language => Language.english, :password => "changeme", :password_confirmation => "changeme")
        User.ignore_blank_passwords = false
      end
    end
  end
end