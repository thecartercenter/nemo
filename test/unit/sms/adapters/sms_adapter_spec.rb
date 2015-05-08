require 'spec_helper'

describe Sms::Adapters::SmsAdapter do
  before do
    # copy settings
    @mission = get_mission
    @mission.setting.load
  end

  it "delivering a message with one recipient should work" do
    each_adapter(:can_deliver? => true) do |adapter|
      expect(:body => "foo"))).to eq(true, adapter.deliver(Sms::Reply.new(:to => "+15556667777")
    end
  end

  it "delivering a message with no recipients should raise an error" do
    each_adapter(:can_deliver? => true) do |adapter|
      assert_raise(Sms::Error){adapter.deliver(Sms::Reply.new(:to => nil, :body => "foo"))}
    end
  end

  it "deliering a message with no body should raise an error" do
    each_adapter(:can_deliver? => true) do |adapter|
      assert_raise(Sms::Error){adapter.deliver(Sms::Reply.new(:to => "+15556667777", :body => ""))}
    end
  end

  private

    # loops over each known adapter and yields to a block
    def each_adapter(options)
      Sms::Adapters::Factory.products(options).each do |klass|
        yield(klass.new)
      end
    end
end
