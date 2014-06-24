def get_mission
  Mission.find_by_name("MissionWithSettings") || FactoryGirl.create(:mission)
end

FactoryGirl.define do
  factory :mission do

    name "MissionWithSettings"
    setting {
      # use Saskatchewan timezone b/c no DST
      Setting.new(
        :timezone => "Saskatchewan",
        :preferred_locales_str => "en",
        :outgoing_sms_adapter => "IntelliSms",
        :intellisms_username => "user",
        :intellisms_password => "pass"
      )
    }
  end

  factory :mission_with_full_heirarchy, parent: :mission do
    name "MissionWithFullHeirarchy"

    after(:create) do |mission, evaluator|
      create(:broadcast, :mission => mission)

      # creates option_set, optionings, option_levels, and options
      os = create(:multilevel_option_set, :mission => mission)

      # creates questionings and questions
      form = create(:form, :mission => mission, :question_types => %w(integer text))

      # adds a multi-level Question, so that we get Subquestions
      create(:question, :qtype_name => 'select_one', :option_set => os, :mission => mission)

      create(:report, :mission => mission)

      # creates answers and choices
      create(:response, :mission => mission, :form => form)
    end
  end

end
