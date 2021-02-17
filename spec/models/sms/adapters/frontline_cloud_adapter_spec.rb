# frozen_string_literal: true

require "rails_helper"

describe Sms::Adapters::FrontlineCloudAdapter, :sms do
  include_context "sms adapters"

  let(:mission_config) { double(incoming_sms_numbers: [], frontlinecloud_api_key: "abc") }
  let(:adapter) { Sms::Adapters::Factory.instance.create("FrontlineCloud", config: mission_config) }

  it_behaves_like "all adapters that can deliver messages"

  it "should be created by factory" do
    expect(adapter).to_not(be_nil)
  end

  it "should have correct service name" do
    expect(adapter.service_name).to eq("FrontlineCloud")
  end

  it "should recognize an incoming request with the proper params" do
    request = double(params: frontlinecloud_params)
    expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be_truthy
  end

  it "should not recognize an incoming request without the special frontlinecloud param" do
    request = double(params: frontlinecloud_params("frontlinecloud" => nil))
    expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be_falsey
  end

  it "should not recognize an incoming request without the other params" do
    request = double(params: frontlinecloud_params("body" => nil, "from" => nil, "sent_at" => nil))
    expect(adapter.class.recognize_receive_request?(request, config: mission_config)).to be_falsey
  end

  it "should correctly parse a frontlinecloud-style request" do
    Time.zone = ActiveSupport::TimeZone["Saskatchewan"]

    request = double(params: frontlinecloud_params)
    msg = adapter.receive(request)

    parsing_expectations(msg, request)
  end

  it "should correctly parse a frontlinecloud-style request even if incoming_sms_numbers is empty" do
    Time.zone = ActiveSupport::TimeZone["Saskatchewan"]

    request = double(params: frontlinecloud_params)
    msg = adapter.receive(request)

    parsing_expectations(msg, request)
  end
end

def frontlinecloud_params(params = {})
  default_params = {
    "frontlinecloud" => "1",
    "body" => "foo",
    "from" => "+2348036801489",
    "sent_at" => Time.zone.now.to_i * 1000 # frontlinecloud sends millisecond timestamps
  }
  default_params.merge(params).compact
end

def parsing_expectations(msg, request)
  expect(msg).to be_a(Sms::Incoming)
  expect(msg.to).to be_nil
  expect(msg.from).to eq("+2348036801489")
  expect(msg.body).to eq("foo")
  expect(msg.adapter_name).to eq("FrontlineCloud")
  expect(msg.sent_at).to eq(Time.zone.at((request.params["sent_at"].to_i / 1000)))
  expect(msg.sent_at.zone).not_to eq("UTC")
  expect(msg.mission).to be_nil # This gets set in controller.
end
