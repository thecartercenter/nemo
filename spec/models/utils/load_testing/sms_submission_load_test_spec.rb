# frozen_string_literal: true

require "rails_helper"

describe Utils::LoadTesting::SmsSubmissionLoadTest do
  let(:setting) { build(:setting, incoming_sms_token: "token") }
  let(:mission) { create(:mission, name: "SMS Submission Load Test Mission", setting: setting) }
  let(:form) do
    create(:form, :live, mission: mission, question_types: %w[
      text long_text integer counter decimal
      select_one select_multiple datetime date time
    ])
  end

  let(:user) { create(:user, phone: "+1234567890") }
  let(:threads) { 1 }
  let(:duration) { 5 }

  it "generates expected test plan" do
    test = described_class.new(
      threads: threads,
      duration: duration,
      user_id: user.id,
      form_id: form.id
    )

    path = test.generate_plan
    jmx = File.read(path.join("testplan.jmx"))

    expect(jmx).to include("/m/smssubmissionloadtestmission/sms/submit/token")
  end
end
