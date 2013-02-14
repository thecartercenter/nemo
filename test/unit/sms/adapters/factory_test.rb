require 'test_helper'

class Sms::Adapters::FactoryTest < ActiveSupport::TestCase
  test "create should work for existing adapters" do
    assert_equal("Sms::Adapters::IntelliSmsAdapter", Sms::Adapters::Factory.new.create("IntelliSms").class.name)
    assert_equal("IntelliSMS", Sms::Adapters::Factory.new.create("IntelliSms").service_name)
  end
  
  test "create should error for non-existent adapters" do
    assert_raise(ArgumentError){Sms::Adapters::Factory.new.create("Foo")}
  end
end
