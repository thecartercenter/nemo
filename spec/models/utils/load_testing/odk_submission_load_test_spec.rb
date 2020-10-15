# frozen_string_literal: true

require "rails_helper"

describe Utils::LoadTesting::ODKSubmissionLoadTest do
  let(:mission) { create(:mission, name: "ODK Submission Load Test Mission") }
  let(:form) do
    create(:form, :live, mission: mission, question_types: %w[
      text long_text integer counter decimal location
      select_one select_multiple datetime date time barcode
    ])
  end

  let(:username) { "admin" }
  let(:password) { "Testing123" }
  let(:threads) { 1 }
  let(:duration) { 5 }

  it "generates expected test plan" do
    test = described_class.new(
      threads: threads,
      duration: duration,
      username: username,
      password: password,
      form_id: form.id
    )

    path = test.generate_plan
    output = File.read(path.join("testplan.jmx"))

    expect(output).to include("/en/m/odksubmissionloadtestmission/submission")
    expect(output).to include("Basic YWRtaW46VGVzdGluZzEyMw==")
  end
end
