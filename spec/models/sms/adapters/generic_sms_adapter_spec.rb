# frozen_string_literal: true

require "spec_helper"

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
        configatron.generic_sms_config = nil
      end

      it "should return false" do
        request = double(params: {"num" => "1", "msg" => "1", "foo" => "1"})
        expect(adapter.class.recognize_receive_request?(request)).to be false
      end
    end

    context "with params-only configuration" do
      before do
        configatron.generic_sms_config = {"params" => {"from" => "num", "body" => "msg"}, "response" => "x"}
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
        configatron.generic_sms_config = {
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
        configatron.generic_sms_config = {
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
end
