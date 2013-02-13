require 'test_helper'

class Sms::AdaptersFactoryTest < ActiveSupport::TestCase
  test "create should work for existing adapters" do
    assert_equal("Sms::Adapters::IntelliSmsAdapter", Sms::Adapters::Factory.new.create("IntelliSms").class.name)
  end
  
  test "create should error for non-existent adapters" do
    assert_raise(ArgumentError){Sms::Adapters::Factory.new.create("Foo")}
  end
end
