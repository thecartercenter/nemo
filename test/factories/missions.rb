def get_mission
  Mission.first || FactoryGirl.create(:mission)
end

FactoryGirl.define do
  sequence(:name) { |n| "Mission #{n}" }

  factory :mission do
    name
    setting {
      # use Saskatchewan timezone b/c no DST
      Setting.new(
        timezone: "Saskatchewan",
        preferred_locales_str: "en",
        outgoing_sms_adapter: "IntelliSms",
        intellisms_username: "user",
        intellisms_password: "pass"
      )
    }
  end

  factory :mission_with_full_heirarchy, parent: :mission do
    name
    after(:create) do |mission, evaluator|
      create(:broadcast, mission: mission)

      # creates questionings and questions
      form = create(:form, mission: mission,
        question_types: ['integer', 'text', ['integer', 'integer'], 'text', 'select_one'], use_multilevel_option_set: true)

      create(:report, mission: mission)

      # creates answers and choices
      create(:response, mission: mission, form: form)
    end
  end
end
