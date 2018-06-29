require 'rails_helper'

describe Sms::Adapters::FrontlineSmsAdapter, :sms do
  before :all do
    @adapter = Sms::Adapters::Factory.instance.create('FrontlineSms')
  end

  it 'should be created by factory' do
    expect(@adapter).to_not be_nil
  end

  it 'should have correct service name' do
    expect(@adapter.service_name).to eq 'FrontlineSms'
  end

  it 'should raise exception on deliver' do
    expect{@adapter.deliver(nil)}.to raise_error(NotImplementedError)
  end

  it 'should recognize an incoming request with the proper params' do
    request = double(params: {'frontline' => '1', 'from' => '1', 'text' => '1'})
    expect(@adapter.class.recognize_receive_request?(request)).to be_truthy
  end

  it 'should not recognize an incoming request without the special frontline param' do
    request = double(params: {'from' => '1', 'text' => '1'})
    expect(@adapter.class.recognize_receive_request?(request)).to be_falsey
  end

  it 'should not recognize an incoming request without the other params' do
    request = double(params: {'frontline' => '1'})
    expect(@adapter.class.recognize_receive_request?(request)).to be_falsey
  end

  it 'should correctly parse a frontline-style request' do
    Time.zone = ActiveSupport::TimeZone['Saskatchewan']

    request = double(params: {'frontline' => '1', 'text' => 'foo', 'from' => '+2348036801489'})
    msg = @adapter.receive(request)
    expect(msg).to be_a Sms::Incoming
    expect(msg.to).to be_nil
    expect(msg.from).to eq '+2348036801489'
    expect(msg.body).to eq 'foo'
    expect(msg.adapter_name).to eq 'FrontlineSms'
    expect((msg.sent_at - Time.now).abs).to be <= 5
    expect(msg.sent_at.zone).not_to eq 'UTC'
    expect(msg.mission).to be_nil # This gets set in controller.
  end

  it 'should correctly parse a frontline-style request even if incoming_sms_numbers is empty' do
    configatron.incoming_sms_numbers = []
    request = double(params: {'frontline' => '1', 'text' => 'foo', 'from' => '+2348036801489'})
    msg = @adapter.receive(request)
    expect(msg.body).to eq 'foo'
    expect(msg.to).to be_nil
  end
end
