namespace :db do
  desc "Seed the current environment's database." 
  task :seedy => :environment do
    ActiveRecord::Base.transaction do

      # generate all permanent, mandatory seeds
      to_seed = [Language, Role, Settable, FormType, QuestionType, Report::ResponseAttribute, Report::Aggregation]
      to_seed.each{|c| c.generate}
      
      # check for mysql timezone info
      zone_test = ActiveRecord::Base.connection.execute("SELECT CONVERT_TZ('2012-01-01 12:00:00', 'UTC', 'America/New_York')")
      if zone_test.fetch_row[0].nil?
        puts "WARNING: MySQL timezone tables have not been populated. Some date functionality will not work without these. " +
          "See the MySQL manual for instructions on populating them."
      end
    end
  end
end