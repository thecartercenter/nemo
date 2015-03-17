RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, clean_with_truncation: true) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean

    # Ensure sequences are reset
    FactoryGirl.reload
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    DatabaseCleaner.start if example.metadata[:database_cleaner] != :all
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean if example.metadata[:database_cleaner] != :all
  end

  config.after(:all, database_cleaner: :all) do
    DatabaseCleaner.clean_with(:truncation)
  end
end
