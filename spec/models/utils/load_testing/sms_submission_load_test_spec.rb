# frozen_string_literal: true

require "rails_helper"

describe Utils::LoadTesting::SmsSubmissionLoadTest do
  include_context "load_testing"

  let(:setting) { build(:setting, incoming_sms_token: "token") }
  let(:mission) { create(:mission, name: "SMS Submission Load Test Mission", setting: setting) }
  let(:form) do
    create(:form, mission: mission, question_types: %w[
      text long_text integer counter decimal
      select_one select_multiple datetime date time
    ])
  end

  let(:user) { create(:user, phone: "+1234567890") }
  let(:threads) { 1 }
  let(:duration) { 5 }

  before { form.publish! }

  it "generates expected test plan" do
    test = described_class.new(
      threads: threads,
      duration: duration,
      user_id: user.id,
      form_id: form.id
    )

    Timecop.freeze(DateTime.new(2018, 12, 5, 0, 0, 0)) do
      path = test.generate_plan
      actual_content = File.read(path.join("testplan.jmx"))
      expected_content = fixture_file("test_plans/sms_submission.jmx")

      expect(without_timestamps(actual_content)).to eq(without_timestamps(expected_content))
    end
  end
end
