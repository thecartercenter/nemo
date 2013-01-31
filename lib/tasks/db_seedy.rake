namespace :db do
  desc "Seed the current environment's database." 
  task :seedy => :environment do
    ActiveRecord::Base.transaction do
      # generate all permanent, mandatory seeds
      to_seed = [Role, QuestionType]
      to_seed.each{|c| c.generate}
    end
  end
end