# frozen_string_literal: true

require "rails_helper"

describe "mission destroy" do
  let!(:mission) { create(:mission) }
  let(:users) { create_list(:user, 3, mission: mission) }
  let(:before_counts) do
    {
      "Answer": 5,
      "Assignment": 3,
      "Broadcast": 1,
      "Choice": 2,
      "Condition": 6,
      "Constraint": 2,
      "Form": 2,
      "FormVersion": 1,
      "Mission": 1,
      "Operation": 1,
      "Option": 10,
      "OptionNode": 20,
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
  let(:after_counts) { before_counts.map { |k, _| [k, 0] }.to_h }

  before do
    Setting.load_for_mission(mission)

    user_groups = create_list(:user_group, 2, mission: mission)
    users.each { |u| create(:user_group_assignment, user: u, user_group: user_groups.sample) }
    users[0].update!(last_mission: mission)

    broadcast = create(:broadcast, mission: mission, medium: "sms", recipients: users)
    broadcast.deliver # Creates Sms::Broadcast

    opt_set = create(:option_set, option_names: :multilevel, mission: mission)
    opt_set.replicate(mode: :clone)

    form = create(:form, mission: mission,
                         question_types: ["integer", "select_one", %w[integer integer], "select_multiple"])
    form.publish! # Creates version
    create(:question, qtype_name: "select_one", option_set: opt_set, mission: mission)
    create(:condition, ref_qing: form.c[0], conditionable: form.c[3], mission: mission)
    create(:skip_rule, source_item: form.c[1], destination: "item", dest_item: form.c[3],
                       conditions_attributes: [{ref_qing_id: form.c[0].id, op: "eq", value: "5"}])
    create(:constraint, questioning: form.c[1],
                        conditions_attributes: [{ref_qing_id: form.c[1].id, op: "gt",
                                                 option_node: form.c[1].option_set.c[1]}])
    form.replicate(mode: :clone) # Tests that cloned objects can be deleted

    create(:operation, mission: mission, creator: users[0])

    create(:list_report, mission: mission)
    create(:response, user: users.first, mission: mission, form: form,
                      answer_values: [3, "Cat", [5, 6], %w[Cat Dog]])
  end

  it "should delete all objects in mission" do
    expect(actual_counts).to eq(before_counts)
    mission.destroy
    expect(actual_counts).to eq(after_counts)
    expect(users[0].reload.last_mission).to be_nil
  end

  def actual_counts
    before_counts.keys.map { |k| [k, k.to_s.constantize.count] }.to_h
  end
end
