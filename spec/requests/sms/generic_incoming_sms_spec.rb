# frozen_string_literal: true

require "rails_helper"

describe "generic incoming sms", :sms do
  include_context "incoming sms"

  before do
    get_mission.setting.update!(generic_sms_config: config)
  end

  # Note that in the specs below, getting a "can't find you" response is a success.

  context "general" do
    let(:config) do
      {
        "params" => {"from" => "num", "body" => "msg"},
        "response" => "%{reply}"
      }
    end

    it "delivers via reply, not adapter" do
      expect_no_messages_delivered_through_adapter do
        do_request
      end
    end

    it "message with no reply should result in empty response" do
      # Non-numeric from number results in no reply.
      do_incoming_request(from: "foo", incoming: {body: "foo", adapter: "Generic"})
      expect(response.body).to eq("")
      expect(response.status).to eq(204)
    end
  end

  context "with matchHeaders" do
    let(:config) do
      {
        "params" => {"from" => "num", "body" => "msg"},
        "response" => "<msg>%{reply}</msg>",
        "matchHeaders" => {"UserAgent" => "FooBar"}
      }
    end

    context "without required header" do
      it "raises error" do
        expect { do_request }.to raise_error(Sms::Error)
      end
    end

    context "with required header" do
      it "sets correct reply body" do
        do_request(headers: {"UserAgent" => "FooBar"})
        expect(response.body).to eq("<msg>Sorry, we couldn't find you in the system.</msg>")
      end
    end
  end

  describe "response types" do
    context "default response type" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "%{reply}"
        }
      end

      it "sets correct reply body and type" do
        do_request
        expect(response.body).to eq("Sorry, we couldn't find you in the system.")
        expect(response.content_type).to eq("text/plain; charset=utf-8")
      end
    end

    context "specified response type" do
      let(:config) do
        {
          "params" => {"from" => "num", "body" => "msg"},
          "response" => "<msg>%{reply}</msg>",
          "responseType" => "text/xml"
        }
      end

      it "sets correct reply body and type" do
        do_request
        expect(response.body).to eq("<msg>Sorry, we couldn&#39;t find you in the system.</msg>")
        expect(response.content_type).to eq("text/xml; charset=utf-8")
      end
    end
  end

  def do_request(extra_params = {})
    do_incoming_request(
      {from: "+1234567890", incoming: {body: "foo", adapter: "Generic"}}.merge(extra_params)
    )
  end
end
