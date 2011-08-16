require 'fileutils'
namespace :db do
  desc "Load seed fixtures (from db/fixtures) into the current environment's database." 
  task :seed => :environment do
    require 'active_record/fixtures'
    Dir.glob(RAILS_ROOT + '/db/fixtures/*.yml').each do |file|
      Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
      FileUtils.cp(file, file.gsub(/\/db\/fixtures\//, "/test/fixtures/"))
    end
  end
end