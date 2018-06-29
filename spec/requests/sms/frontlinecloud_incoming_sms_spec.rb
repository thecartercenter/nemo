require "rails_helper"

describe "frontlinecloud incoming sms", :sms do
  include_context "incoming sms"

  before :all do
    @user = get_user
    setup_form(questions: %w(integer integer), required: true)
  end

  it "reply should be sent via adapter" do
    do_incoming_request(from: "+1234567890", incoming: {body: "foo", adapter: "FrontlineCloud"})
    expect(configatron.outgoing_sms_adapter.deliveries.size).to eq(1)
  end
end
