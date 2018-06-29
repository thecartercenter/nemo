# frozen_string_literal: true

require "rails_helper"

describe "generic incoming sms", :sms do
  include_context "incoming sms"

  before do
    @user = get_user
    setup_form(questions: %w[integer integer], required: true)
    get_mission.setting.update!(generic_sms_config: {
      "params" => {"from" => "num", "body" => "msg"},
      "response" => "<msg>%{reply}</msg>",
      "matchHeaders" => {"UserAgent" => "FooBar"}
    })
  end

  it "sets correct reply body" do
    do_incoming_request(from: "+1234567890", incoming: {body: "foo", adapter: "Generic"})
    expect_no_messages_delivered_through_adapter
    expect(response.body).to eq("<msg>Sorry, we couldn't find you in the system.</msg>")
  end

  it "message with no reply should result in empty response" do
    # Non-numeric from number results in no reply.
    do_incoming_request(from: "foo", incoming: {body: "foo", adapter: "Generic"})
    expect(response.body).to eq("")
    expect(response.status).to eq(204)
  end
end
