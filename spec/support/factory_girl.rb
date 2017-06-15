require 'support/media_spec_helpers'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:each, reset_factory_sequences: true) do
    FactoryGirl.reload
  end
end

if defined? FactoryGirl
  FactoryGirl::SyntaxRunner.send(:include, MediaSpecHelpers::FileHandling)
end
