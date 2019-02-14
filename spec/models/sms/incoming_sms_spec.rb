# frozen_string_literal: true

require "rails_helper"

describe Sms::Incoming, :sms do
  let!(:user) { create(:user, phone: "1234567890") }
  let(:from) { "1234567890" }
  let(:incoming) { create(:sms_incoming, from: from, body: "test") }

  it "should lookup user" do
    expect(incoming.user).to eq(user)
  end

  context "with unrecognized number" do
    let(:from) { "6667778888" }

    it "should set user to nil" do
      expect(incoming.user).to be_nil
    end
  end
end
