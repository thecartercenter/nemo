require 'test_helper'

class Sms::Adapters::FactoryTest < ActiveSupport::TestCase
  test "create should error for non-existent adapters" do
    assert_raise(ArgumentError){Sms::Adapters::Factory.new.create("Foo")}
  end
end
