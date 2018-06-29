require "rails_helper"

describe "mission destroy" do
  let!(:mission) { create(:mission_with_full_heirarchy) }
  let(:expected_counts) do
    {
      "Answer": 5,
      "Assignment": 3,
      "Broadcast": 1,
      "Choice": 2,
      "Condition": 4,
      "Form": 2,
      "Mission": 1,
      "Option": 10,
      "OptionNode": 13,
      "OptionSet": 4,
      "QingGroup": 4,
      "Question": 6,
      "Questioning": 10,
      "Report::Report": 1,
      "Response": 1,
      "Sms::Message": 1,
      "SkipRule": 2,
      "UserGroup": 2,
      "UserGroupAssignment": 3
    }
  end
  let(:deleted_counts) { expected_counts.map { |k, v| [k, 0] }.to_h }

  it "should delete all objects in mission" do
    expect(actual_counts).to eq expected_counts
    mission.destroy
    expect(actual_counts).to eq deleted_counts
  end

  def actual_counts
    expected_counts.keys.map { |k| [k, k.to_s.constantize.count] }.to_h
  end
end
