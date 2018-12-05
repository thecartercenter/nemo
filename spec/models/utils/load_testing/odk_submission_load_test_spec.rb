# frozen_string_literal: true

require "rails_helper"

describe Utils::LoadTesting::OdkSubmissionLoadTest do
  include_context "load_testing"

  let(:mission) { create(:mission, name: "ODK Submission Load Test Mission") }
  let(:form) do
    create(:form, mission: mission, question_types: %w[
      text long_text integer counter decimal location
      select_one select_multiple datetime date time barcode
    ])
  end

  let(:username) { "admin" }
  let(:password) { "Testing123" }
  let(:threads) { 1 }
  let(:duration) { 5 }

  before { form.publish! }

  it "generates expected test plan" do
    test = described_class.new(
      threads: threads,
      duration: duration,
      username: username,
      password: password,
      form_id: form.id
    )

    path = test.generate_plan
    actual_content = File.read(path.join("testplan.jmx"))
    expected_content = fixture_file("test_plans/odk_submission.jmx")

    expect(without_timestamps(actual_content)).to eq(without_timestamps(expected_content))
  end
end
