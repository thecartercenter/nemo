require 'spec_helper'

describe Sms::Adapters::Factory, :sms do
  it "create should error for non-existent adapters" do
    expect{ Sms::Adapters::Factory.new.create("Foo") }.to raise_error(ArgumentError)
  end
end
