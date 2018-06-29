require 'rails_helper'

# Tests methods common to all adapters.
describe Sms::Adapters::Adapter, :sms do
  before do
    get_mission.setting.load
  end

  it "delivering a message with one recipient should work" do
    each_adapter(can_deliver?: true) do |adapter|
      expect(adapter.deliver(Sms::Reply.new(to: "+15556667777", body: "foo"))).to be true
    end
  end

  it "delivering a message with no recipients should raise an error" do
    each_adapter(can_deliver?: true) do |adapter|
      expect{ adapter.deliver(Sms::Reply.new(to: nil, body: "foo")) }.to raise_error(Sms::Error)
    end
  end

  it "deliering a message with no body should raise an error" do
    each_adapter(can_deliver?: true) do |adapter|
      expect{ adapter.deliver(Sms::Reply.new(to: "+15556667777", body: "")) }.to raise_error(Sms::Error)
    end
  end

  private

  # loops over each known adapter and yields to a block
  def each_adapter(options)
    Sms::Adapters::Factory.products(options).each do |klass|
      Sms::Adapters::Factory.instance.create(klass)
    end
  end
end
