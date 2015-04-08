RSpec.configure do |config|

  config.before(:suite) do
    ThinkingSphinx::Test.init
  end

  config.around(:each, sphinx: true) do |example|
    ThinkingSphinx::Test.run do
      example.run
    end
  end
end

