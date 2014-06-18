require 'spec_helper'

describe 'frontline sms adapter' do
  before do
    @adapter = Sms::Adapters::Factory.new.create('FrontlineSms')
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
    request = build_request('frontline' => '1', 'from' => '1', 'text' => '1', 'sent' => '1')
    expect(@adapter.class.recognize_receive_request?(request)).to be_true
  end

  it 'should not recognize an incoming request without the special frontline param' do
    request = build_request('from' => '1', 'text' => '1', 'sent' => '1')
    expect(@adapter.class.recognize_receive_request?(request)).to be_false
  end

  it 'should not recognize an incoming request without the other params' do
    request = build_request('frontline' => '1')
    expect(@adapter.class.recognize_receive_request?(request)).to be_false
  end

  it 'should correctly parse a frontline-style request' do
    Time.zone = ActiveSupport::TimeZone['Saskatchewan']

    request = build_request('frontline' => '1', 'text' => 'foo', 'sent' => '2014-06-07 15:10:48.019', 'from' => '+2348036801489')
    msg = @adapter.receive(request)
    expect(msg.to).to be_nil
    expect(msg.from).to eq '+2348036801489'
    expect(msg.direction).to eq 'incoming'
    expect(msg.body).to eq 'foo'
    expect(msg.adapter_name).to eq 'FrontlineSms'
    expect(msg.sent_at).to eq Time.zone.parse('2014-06-07 15:10:48.019')
    expect(msg.sent_at.zone).not_to eq 'UTC'
    expect(msg.mission).to be_nil # This gets set in controller.
  end

  def build_request(params)
    double.tap{|r| allow(r).to receive(:POST).and_return(params)}
  end
end
