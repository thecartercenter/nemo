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

      os = create(:option_set, multi_level: true, mission: mission)

      # creates questionings and questions
      # TODO change factory to generate root group, questions should have root group as parent
    #  form = create(:form, mission: mission, question_types: %w(integer text text))
      # TODO change factory to support this syntax
      form = create(:form, mission: mission)
      debugger
      add_questions_to_form(form, ['integer', ['text', 'text']])
      
      create(:question, qtype_name: 'select_one', option_set: os, mission: mission)

      create(:report, mission: mission)

      # creates answers and choices
      create(:response, mission: mission, form: form)
    end
  end
end
