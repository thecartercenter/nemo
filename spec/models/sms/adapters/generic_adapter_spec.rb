# frozen_string_literal: true

require "rails_helper"

describe Sms::Adapters::GenericAdapter, :sms do
  include_context "sms adapters"

  let(:mission_config) { double(generic_sms_config: config) }
  let(:adapter) { Sms::Adapters::Factory.instance.create("Generic", config: mission_config) }

  describe "general" do
    let(:config) do
      {"params" => {"from" => "num", "body" => "msg"}, "response" => "x"}
    end

    it "should be created by factory" do
      expect(adapter).not_to be_nil
    end

    it "should have correct service name" do
      expect(adapter.service_name).to eq("Generic")
    end

    it "should raise exception on deliver" do
      expect { adapter.deliver(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe ".recognize_receive_request" do
    context "with no configuration" do
      let(:config) do
        nil
      end

      it "should return false" do
        request = double(params: {"num" => "1", "msg" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(false)
      end
    end

    context "with params-only configuration" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "x"
        }
      end

      it "should match request with matching params" do
        request = double(params: {"num" => "1", "msg" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(true)
      end

      it "should not match request with missing param" do
        request = double(params: {"num" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(false)
      end
    end

    context "with params and matchHeaders configuration" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "x",
          "matchHeaders" => {"Header1" => "foo", "Header2" => "bar"}
        }
      end

      it "should match request with matching params and headers" do
        request = double(
          params: {"num" => "1", "msg" => "1", "foo" => "1"},
          headers: {"Header1" => "foo", "Header2" => "bar"}
        )
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(true)
      end

      it "should not match request with matching params but missing header" do
        request = double(
          params: {"num" => "1", "msg" => "1", "foo" => "1"},
          headers: {"Header1" => "foo"}
        )
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(false)
      end

      it "should not match request with missing param but matching headers" do
        request = double(
          params: {"num" => "1", "foo" => "1"},
          headers: {"Header1" => "foo", "Header2" => "bar"}
        )
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(false)
      end
    end

    context "with invalid matchHeaders configuration" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "x",
          "matchHeaders" => "x"
        }
      end

      it "should match request with matching params and ignore headers" do
        request = double(
          params: {"num" => "1", "msg" => "1", "foo" => "1"},
          headers: {"Header1" => "foo", "Header2" => "bar"}
        )
        expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be(true)
      end
    end
  end

  describe "#receive" do
    let(:config) do
      {"params" => {"from" => "num", "body" => "msg"}, "response" => "x"}
    end

    before do
      Time.zone = ActiveSupport::TimeZone["Saskatchewan"]
    end

    it "should correctly parse a request" do
      request = double(params: {"msg" => "foo", "num" => "+2348036801489"})
      msg = adapter.receive(request)
      expect(msg).to be_a(Sms::Incoming)
      expect(msg.to).to be_nil
      expect(msg.from).to eq("+2348036801489")
      expect(msg.body).to eq("foo")
      expect(msg.adapter_name).to eq("Generic")
      expect((msg.sent_at - Time.current).abs).to be <= 5
      expect(msg.sent_at.zone).not_to eq("UTC")
      expect(msg.mission).to be_nil # This gets set in controller.
    end
  end

  describe "#response_body" do
    context "default type" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "Reply: %{reply}" # rubocop:disable Style/FormatStringToken
        }
      end

      it "interpolates" do
        reply = double(body: "hallo!")
        expect(adapter.response_body(reply)).to eq("Reply: hallo!")
      end
    end

    context "xml type" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "<msg>%{reply}</msg>", # rubocop:disable Style/FormatStringToken
          "responseType" => "application/xml"
        }
      end

      it "escapes properly" do
        reply = double(body: "ten < twenty")
        expect(adapter.response_body(reply)).to eq("<msg>ten &lt; twenty</msg>")
      end
    end

    context "json type" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => %({"foo":"bar","msg":%{reply}}), # rubocop:disable Style/FormatStringToken
          "responseType" => "application/json"
        }
      end

      it "escapes properly" do
        reply = double(body: %(I said "Hey!"))
        expect(adapter.response_body(reply)).to eq(%({"foo":"bar","msg":"I said \\"Hey!\\""}))
      end
    end
  end

  describe "#response_content_type" do
    context "default" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "%{reply}" # rubocop:disable Style/FormatStringToken
        }
      end

      it "should default to plain text" do
        expect(adapter.response_content_type).to eq("text/plain")
      end
    end

    context "specified" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "<msg>%{reply}</msg>", # rubocop:disable Style/FormatStringToken
          "responseType" => "text/xml"
        }
      end

      it "should respect setting" do
        expect(adapter.response_content_type).to eq("text/xml")
      end
    end
  end
end
