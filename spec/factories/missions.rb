def get_mission
  Mission.order(:created_at).first || create(:mission)
end

FactoryGirl.define do
  sequence(:name) { |n| "Mission #{n}" }

  factory :mission do
    transient do
      with_user nil
      role_name :coordinator
    end

    name
    setting { build(:setting) }

    after(:create) do |mission, evaluator|
      mission.assignments.create(user: evaluator.with_user, role: evaluator.role_name.to_s) if evaluator.with_user
    end
  end

  factory :mission_with_full_heirarchy, parent: :mission do
    name
    after(:create) do |mission, evaluator|
      Setting.load_for_mission(mission)

      users = create_list(:user, 3, mission: mission)

      user_groups = create_list(:user_group, 2, mission: mission)
      user_group_assignments = users.each do |user|
        create(:user_group_assignment, user: user, user_group: user_groups.sample)
      end

      broadcast = create(:broadcast, mission: mission, medium: "sms", recipients: users)

      # Deliver broadcast so that Sms::Broadcast gets created
      broadcast.deliver

      os = create(:option_set, multilevel: true, mission: mission)

      # test that cloned objects can be deleted
      os.replicate(mode: :clone)

      # creates questionings and questions
      form = create(:form, mission: mission,
        question_types: ["integer", "select_one", ["integer", "integer"], "select_multiple"])

      create(:question, qtype_name: "select_one", option_set: os, mission: mission)

      create(:condition, ref_qing: form.c.first, conditionable: form.c.last, mission: mission)

      # test that cloned objects can be deleted
      form.replicate(mode: :clone)

      create(:report, mission: mission)

      # creates answers and choices
      create(:response, user: users.first, mission: mission, form: form, answer_values: [3, "Cat", [5, 6], %w(Cat Dog)])
    end
  end
end
