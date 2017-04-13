require "spec_helper"

describe Mission do
  it_behaves_like "has a uuid"

  describe "terminate", :investigate do
    let!(:mission) { create(:mission_with_full_heirarchy) }
    let(:expected_counts) do
      { mission: 1, broadcast: 1, assignment: 3, form: 2, question: 6, questioning: 10, qing_group: 4, option: 10,
        option_node: 13, option_set: 4, condition: 2, report_report: 1, response: 1, answer: 5, choice: 2,
        sms_message: 1, user_group: 2, user_group_assignment: 3 }
    end
    let(:deleted_counts) { expected_counts.map { |k, v| [k, 0] }.to_h }

    it "should delete all objects in mission" do
      expect(obj_counts).to eq expected_counts
      mission.terminate
      expect(obj_counts).to eq deleted_counts
    end

    def obj_counts
      [Mission, Broadcast, Assignment, Form, Question, Questioning, QingGroup, Option, OptionNode, OptionSet, Condition,
        Report::Report, Response, Answer, Choice, Sms::Message, UserGroup, UserGroupAssignment].map do |u| [u.model_name.param_key.to_sym, u.count]
      end.to_h
    end
  end
end
