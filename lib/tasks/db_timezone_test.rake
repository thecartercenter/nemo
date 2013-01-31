namespace :db do
  desc "Seed the current environment's database." 
  task :timezone_test => :environment do
    # tests if db has timezone tables.
    zone_test = ActiveRecord::Base.connection.execute("SELECT CONVERT_TZ('2012-01-01 12:00:00', 'UTC', 'America/New_York')")
    if zone_test.entries.first && zone_test.entries.first.first.class == Time
      puts "Timezones OK"
    else
      puts "WARNING: MySQL timezone tables have not been populated. Some date functionality will not work without these. " +
        "See the MySQL manual for instructions on populating them."
    end
  end
end