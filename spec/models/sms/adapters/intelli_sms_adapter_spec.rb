require 'spec_helper'

describe Sms::Adapters::IntelliSmsAdapter do
  before :all do
    @adapter = Sms::Adapters::Factory.new.create('IntelliSms')
  end

  it 'should be created by factory' do
    expect(@adapter).to_not be_nil
  end

  it 'should have correct service name' do
    expect(@adapter.service_name).to eq 'IntelliSms'
  end

  it 'should return true on deliver' do
    msg = Sms::Message.new(:to => '+123', :body => 'foo')
    expect(@adapter.deliver(msg)).to be_truthy
  end

  it 'should recognize an incoming request with the proper params' do
    request = {'from' => '1', 'text' => '1', 'sent' => '1', 'msgid' => '1'}
    expect(@adapter.class.recognize_receive_request?(request)).to be_truthy
  end

  it 'should not recognize an incoming request without all the proper params' do
    request = {'from' => '1', 'text' => '1', 'sent' => '1'}
    expect(@adapter.class.recognize_receive_request?(request)).to be_falsey
  end

  it 'should correctly parse an intellisms-style request' do
    Time.zone = ActiveSupport::TimeZone['Saskatchewan']

    request = {'text' => 'foo', 'sent' => '2013-07-03T09:53:00+01:00', 'from' => '2348036801489',
      'msgid' => '1234'}

    msg = @adapter.receive(request)
    expect(msg.to).to be_nil
    expect(msg.from).to eq '+2348036801489'
    expect(msg.direction).to eq 'incoming'
    expect(msg.body).to eq 'foo'
    expect(msg.adapter_name).to eq 'IntelliSms'
    expect(msg.sent_at.utc).to eq Time.utc(2013, 7, 3, 8, 53, 00)
    expect(msg.mission).to be_nil # This gets set in controller.
  end
end
