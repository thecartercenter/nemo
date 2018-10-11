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

  context "broadcast message" do
    let(:msg) { create(:sms_broadcast) }
    let(:messages) { double(:twilio_messages, create: true) }
    let(:client) { double(:twilio_client, messages: messages) }

    before do
      allow(msg).to receive(:recipient_numbers) { ["+12", "+34", "+56", "+78"] }
      allow(@adapter).to receive(:client) { client }
    end

    context "3 non-consecutive failures" do
      before do
        allow(messages).to receive(:create) do |params|
          raise Twilio::REST::RequestError.new, "error" unless params[:to] == "+34"
        end
      end

      it "has at least one success and raises Sms::Errors::PartialError" do
        expect(messages).to receive(:create).with(hash_including(to: "+34"))
        expect { @adapter.deliver(msg, false) }.to raise_error(Sms::Errors::PartialError)
      end
    end

    context "3 consecutive failures" do
      before do
        allow(messages).to receive(:create) do |params|
          raise Twilio::REST::RequestError, "error" unless params[:to] == "+78"
        end
      end

      it "raises Sms::Errors::FatalError" do
        expect(messages).not_to receive(:create).with(hash_including(to: "+78"))
        expect { @adapter.deliver(msg, false) }.to raise_error(Sms::Errors::FatalError)
      end
    end
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
