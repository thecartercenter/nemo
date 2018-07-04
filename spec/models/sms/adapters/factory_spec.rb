require 'rails_helper'

describe Sms::Adapters::Factory, :sms do
  it "create should error for non-existent adapters" do
    expect{ Sms::Adapters::Factory.instance.create("Foo") }.to raise_error(ArgumentError)
  end
end
