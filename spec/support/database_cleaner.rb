RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    if example.metadata[:database_cleaner] != :all
      DatabaseCleaner.start
    end
  end

  config.after(:each) do
    if example.metadata[:database_cleaner] != :all
      DatabaseCleaner.clean
    end
  end

  config.before(:all, database_cleaner: :all) do
    DatabaseCleaner.clean
  end

  config.after(:all, database_cleaner: :all) do
    DatabaseCleaner.clean
  end
end
