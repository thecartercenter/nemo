# frozen_string_literal: true

require "rails_helper"

describe "frontlinecloud incoming sms", :sms do
  include_context "incoming sms"

  before do
    setup_form(questions: %w[integer integer], required: true)
  end

  it "reply should be sent via adapter" do
    do_incoming_request(from: "+1234567890", incoming: {body: "foo", adapter: "FrontlineCloud"})
    expect(Sms::Adapters::Adapter.deliveries.size).to eq(1)
  end
end
