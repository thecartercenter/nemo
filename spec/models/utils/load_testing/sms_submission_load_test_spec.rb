# frozen_string_literal: true

require "rails_helper"

describe Utils::LoadTesting::SmsSubmissionLoadTest do
  let(:setting) { FactoryGirl.build(:setting, incoming_sms_token: "token") }
  let(:mission) { FactoryGirl.create(:mission, name: "SMS Submission Load Test Mission", setting: setting) }
  let(:form) do
    FactoryGirl.create(:form, mission: mission, question_types: %w[
      text long_text integer counter decimal
      select_one select_multiple datetime date time
    ])
  end

  let(:user) { FactoryGirl.create(:user, phone: "+1234567890") }
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

    path = test.generate_plan
    actual_content = File.read(path.join("testplan.jmx"))
    expected_content = fixture_file("test_plans/sms_submission.jmx")

    expect(without_timestamps(actual_content)).to eq(without_timestamps(expected_content))
  end

  def without_timestamps(content)
    content.gsub(/^.+start_time.+$/, "").gsub(/^.+end_time.+$/, "")
  end
end
