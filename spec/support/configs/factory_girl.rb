# frozen_string_literal: true

require "support/helpers/general_spec_helpers"

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:each, reset_factory_sequences: true) do
    FactoryGirl.reload
  end
end

if defined? FactoryGirl
  # Some of these helpers are useful in factories.
  FactoryGirl::SyntaxRunner.send(:include, GeneralSpecHelpers)
end
