def get_mission
  Mission.first || create(:mission)
end

FactoryGirl.define do
  sequence(:name) { |n| "Mission #{n}" }

  factory :mission do
    name
    setting { build(:setting) }
  end

  factory :mission_with_full_heirarchy, parent: :mission do
    name
    after(:create) do |mission, evaluator|
      Setting.load_for_mission(mission)

      users = create_list(:user, 3, mission: mission)

      broadcast = create(:broadcast, mission: mission, medium: "sms", recipients: users)

      # Deliver broadcast so that Sms::Broadcast gets created
      broadcast.deliver

      os = create(:option_set, multi_level: true, mission: mission)

      # creates questionings and questions
      form = create(:form, mission: mission,
        question_types: ['integer', 'select_one', ['integer', 'integer'], 'select_multiple'])

      create(:question, qtype_name: 'select_one', option_set: os, mission: mission)

      create(:report, mission: mission)

      # creates answers and choices
      create(:response, user: users.first, mission: mission, form: form, answer_values: [3, 'Cat', [5, 6], %w(Cat Dog)])
    end
  end
end
