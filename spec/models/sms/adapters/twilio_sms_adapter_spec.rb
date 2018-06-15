require 'rails_helper'

describe Sms::Adapters::TwilioAdapter, :sms do
  before :all do
    configatron.twilio_account_sid = 'AC00000000000000000000000000000000'
    configatron.twilio_auth_token = '12121212121212121212121212121212'
    @adapter = Sms::Adapters::Factory.instance.create('Twilio')
  end

  it 'should be created by factory' do
    expect(@adapter).to_not be_nil
  end

  it 'should have correct service name' do
    expect(@adapter.service_name).to eq 'Twilio'
  end

  it 'should return true on deliver' do
    msg = Sms::Reply.new(to: '+123', body: 'foo')
    expect(@adapter.deliver(msg)).to be_truthy
  end

  it 'should recognize an incoming request with the proper params' do
    request = twilio_request(params: {From: '1', Body: '1'})
    expect(@adapter.class.recognize_receive_request?(request)).to be_truthy
  end

  it 'should not recognize an incoming request without all the proper params' do
    request = double(headers: {}, params: {From: '1', Body: '1'})
    expect(@adapter.class.recognize_receive_request?(request)).to be_falsey
  end

  it 'should correctly parse an twilio-style request' do
    request = twilio_request(params: {Body: 'foo', From: '2348036801489', To: '+123456789'})

    sent_at = Time.utc(2013, 7, 3, 8, 53, 00)
    Timecop.freeze(sent_at) do
      msg = @adapter.receive(request)
      expect(msg).to be_a Sms::Incoming
      expect(msg.to).to eq '+123456789'
      expect(msg.from).to eq '+2348036801489'
      expect(msg.body).to eq 'foo'
      expect(msg.adapter_name).to eq 'Twilio'
      expect(msg.sent_at.utc).to eq sent_at
      expect(msg.mission).to be_nil # This gets set in controller.
    end
  end

  it 'should correctly parse a twilio-style request even if incoming_sms_numbers is empty' do
    configatron.incoming_sms_numbers = []
    request = twilio_request(params: {Body: 'foo', From: '2348036801489'})
    msg = @adapter.receive(request)
    expect(msg.body).to eq 'foo'
    expect(msg.to).to be_nil
  end

  private

    def twilio_request(options={})
      url = options[:url] || 'http://test.localdomain'

      params = (options[:params] || {}).with_indifferent_access

      signature = options[:signature] || begin
        validator = Twilio::Util::RequestValidator.new configatron.twilio_auth_token
        validator.build_signature_for url, params
      end

      headers = { 'X-Twilio-Signature': signature }.with_indifferent_access
      headers.merge!(options[:headers]) if options[:headers]

      double(
        headers: headers,
        params: params,
        original_url: url,
        request_parameters: params,
        query_parameters: {}.freeze
      )
    end
end
