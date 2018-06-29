# frozen_string_literal: true

require "rails_helper"

describe Sms::Adapters::GenericAdapter, :sms do
  let(:adapter) { Sms::Adapters::Factory.instance.create("Generic") }

  it "should be created by factory" do
    expect(adapter).to_not be_nil
  end

  it "should have correct service name" do
    expect(adapter.service_name).to eq "Generic"
  end

  it "should raise exception on deliver" do
    expect { adapter.deliver(nil) }.to raise_error(NotImplementedError)
  end

  describe ".recognize_receive_request" do
    context "with no configuration" do
      before do
        Settings.generic_sms_config = nil
      end

      it "should return false" do
        request = double(params: {"num" => "1", "msg" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request)).to be false
      end
    end

    context "with params-only configuration" do
      before do
        Settings.generic_sms_config = {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "x"
        }
      end

      it "should match request with matching params" do
        request = double(params: {"num" => "1", "msg" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request)).to be true
      end

      it "should not match request with missing param" do
        request = double(params: {"num" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request)).to be false
      end
    end

    context "with params and matchHeaders configuration" do
      before do
        Settings.generic_sms_config = {
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
        expect(adapter.class.recognize_receive_request?(request)).to be true
      end

      it "should not match request with matching params but missing header" do
        request = double(
          params: {"num" => "1", "msg" => "1", "foo" => "1"},
          headers: {"Header1" => "foo"}
        )
        expect(adapter.class.recognize_receive_request?(request)).to be false
      end

      it "should not match request with missing param but matching headers" do
        request = double(
          params: {"num" => "1", "foo" => "1"},
          headers: {"Header1" => "foo", "Header2" => "bar"}
        )
        expect(adapter.class.recognize_receive_request?(request)).to be false
      end
    end

    context "with invalid matchHeaders configuration" do
      before do
        Settings.generic_sms_config = {
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
        expect(adapter.class.recognize_receive_request?(request)).to be true
      end
    end
  end

  describe "#receive" do
    before do
      Settings.generic_sms_config = {"params" => {"from" => "num", "body" => "msg"}, "response" => "x"}
      Time.zone = ActiveSupport::TimeZone["Saskatchewan"]
    end

    it "should correctly parse a request" do
      request = double(params: {"msg" => "foo", "num" => "+2348036801489"})
      msg = adapter.receive(request)
      expect(msg).to be_a Sms::Incoming
      expect(msg.to).to be_nil
      expect(msg.from).to eq "+2348036801489"
      expect(msg.body).to eq "foo"
      expect(msg.adapter_name).to eq "Generic"
      expect((msg.sent_at - Time.current).abs).to be <= 5
      expect(msg.sent_at.zone).not_to eq "UTC"
      expect(msg.mission).to be_nil # This gets set in controller.
    end
  end

  describe "#response_body" do
    before do
      Settings.generic_sms_config = {
        "params" => {"from" => "num", "body" => "msg"},
        "response" => "<msg>%{reply}</msg>"
      }
    end

    it "should return correct response" do
      reply = double(body: "hallo!")
      expect(adapter.response_body(reply)).to eq "<msg>hallo!</msg>"
    end
  end
end
