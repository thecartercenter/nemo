# frozen_string_literal: true

require "rails_helper"

describe Sms::Adapters::TwilioAdapter, :sms do
  include_context "sms adapters"

  let(:msg) { create(:sms_broadcast) }
  let(:messages) { double(:twilio_messages, create: true) }
  let(:client) { double(:twilio_client, messages: messages) }
  let(:mission_config) do
    double(twilio_phone_number: "+1234567890", twilio_account_sid: "AC00000000000000000000000000000000",
           twilio_auth_token: "12121212121212121212121212121212", incoming_sms_numbers: [])
  end
  let(:adapter) { Sms::Adapters::Factory.instance.create("Twilio", config: mission_config) }

  before do
    allow(adapter).to receive(:client).and_return(client)
  end

  it_behaves_like "all adapters that can deliver messages"

  it "should have correct service name" do
    expect(adapter.service_name).to eq("Twilio")
  end

  it "should return true on deliver" do
    msg = build(:sms_reply, to: "+123", body: "foo")
    expect(adapter.deliver(msg)).to be_truthy
  end

  it "should recognize an incoming request with the proper params" do
    request = twilio_request(params: {From: "1", Body: "1"})
    expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(true)
  end

  it "should not recognize an incoming request without all the proper params" do
    request = double(headers: {}, params: {From: "1", Body: "1"})
    expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(false)
  end

  it "should correctly parse an twilio-style request" do
    request = twilio_request(params: {Body: "foo", From: "2348036801489", To: "+123456789"})

    sent_at = Time.utc(2013, 7, 3, 8, 53, 0o0)
    Timecop.freeze(sent_at) do
      msg = adapter.receive(request)
      expect(msg).to be_a(Sms::Incoming)
      expect(msg.to).to eq("+123456789")
      expect(msg.from).to eq("+2348036801489")
      expect(msg.body).to eq("foo")
      expect(msg.adapter_name).to eq("Twilio")
      expect(msg.sent_at.utc).to eq(sent_at)
      expect(msg.mission).to be_nil # This gets set in controller.
    end
  end

  it "should correctly parse a twilio-style request even if incoming_sms_numbers is empty" do
    request = twilio_request(params: {Body: "foo", From: "2348036801489"})
    msg = adapter.receive(request)
    expect(msg.body).to eq("foo")
    expect(msg.to).to be_nil
  end

  context "broadcast message" do
    let(:numbers) { ["+12", "+34", "+56", "+78"] }
    let(:delivery) { adapter.deliver(msg, dry_run: false) }

    before do
      allow(msg).to receive(:recipient_numbers) { numbers }
      allow(messages).to receive(:create) do |params|
        raise Twilio::REST::RequestError, "A Twilio error" if failing_numbers.include?(params[:to])
      end
    end

    context "3 non-consecutive failures" do
      let(:failing_numbers) { ["+12", "+56", "+78"] }

      it "has at least one success and raises Sms::Adapters::PartialSendError" do
        expect(messages).to receive(:create).with(hash_including(to: "+34"))
        expect { delivery }.to raise_error(Sms::Adapters::PartialSendError,
          "A Twilio error\nA Twilio error\nA Twilio error")
      end
    end

    context "3 consecutive failures" do
      let(:failing_numbers) { ["+12", "+34", "+56"] }

      it "raises Sms::Adapters::FatalSendError" do
        expect(messages).not_to receive(:create).with(hash_including(to: "+78"))
        expect { delivery }.to raise_error(Sms::Adapters::FatalSendError,
          "A Twilio error\nA Twilio error\nA Twilio error")
      end
    end

    context "2 failure for 2 recipients" do
      let(:numbers) { ["+12", "+34"] }
      let(:failing_numbers) { ["+12", "+34"] }

      it "raises Sms::Adapters::FatalSendError" do
        expect { delivery }.to raise_error(Sms::Adapters::FatalSendError, "A Twilio error\nA Twilio error")
      end
    end

    context "1 failure for 1 recipients" do
      let(:numbers) { ["+12"] }
      let(:failing_numbers) { ["+12"] }

      it "raises Sms::Adapters::FatalSendError" do
        expect { delivery }.to raise_error(Sms::Adapters::FatalSendError, "A Twilio error")
      end
    end
  end

  private

  def twilio_request(options = {})
    url = options[:url] || "http://test.localdomain"
    params = (options[:params] || {}).with_indifferent_access

    signature = options[:signature] || begin
      validator = Twilio::Util::RequestValidator.new(mission_config.twilio_auth_token)
      validator.build_signature_for(url, params)
    end

    headers = {'X-Twilio-Signature': signature}.with_indifferent_access
    headers.merge!(options[:headers]) if options[:headers]

    double(headers: headers, params: params, original_url: url,
           request_parameters: params, query_parameters: {}.freeze)
  end
end
