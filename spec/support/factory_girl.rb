require 'support/media_spec_helpers'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

if defined? FactoryGirl
  FactoryGirl::SyntaxRunner.send(:include, MediaSpecHelpers::FileHandling)
end
