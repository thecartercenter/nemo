# frozen_string_literal: true

require "spec_helper"

describe "reply sms", :sms do

  before do
    @user = create(:user)
    @sms = create(:sms_reply)
  end

  it "sets correct reply body" do
    login(@user)
    with_env("STUB_REPLY_ERROR" => "I am the reply error") do
      get_s("/en/m/#{get_mission.compact_name}/sms")
    end
    expect(response.body).to include("I am the reply error")
  end
end
