require 'spec_helper'

describe Sms::Adapters::Factory do
  it "create should error for non-existent adapters" do
    assert_raise(ArgumentError){Sms::Adapters::Factory.new.create("Foo")}
  end
end
