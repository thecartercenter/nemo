# frozen_string_literal: true

require "rails_helper"

describe "twilio incoming sms", :sms do
  include_context "incoming sms"

  before do
    setup_form(questions: %w[integer integer], required: true)
    get_mission.setting.update_attribute(:twilio_auth_token, "xxx")
  end

  it "reply body should be response body" do
    expect_no_messages_delivered_through_adapter do
      do_incoming_request(from: "+1234567890", incoming: {body: "foo", adapter: "Twilio"})
    end
    expect(response.body).to eq("Sorry, we couldn't find you in the system.")
    expect(response.headers["Content-Type"]).to match("text/plain")
  end

  it "message with no reply should result in empty response" do
    # Non-numeric from number results in no reply.
    do_incoming_request(from: "foo", incoming: {body: "foo", adapter: "Twilio"})
    expect(response.body).to eq("")
    expect(response.status).to eq(204)
  end
end
