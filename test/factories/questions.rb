FactoryGirl.define do
  factory :question do
    ignore do
      option_names nil
      use_multilevel_option_set false
      add_to_form false
    end

    sequence(:code) { |n| "Question#{n}" }
    qtype_name 'integer'
    sequence(:name) { |n| "Question Title #{n}" }
    sequence(:hint) { |n| "Question Hint #{n}" }
    mission { is_standard ? nil : get_mission }

    option_set do
      if QuestionType[qtype_name].has_options?
        os_attrs = {mission: mission, multi_level: use_multilevel_option_set, is_standard: is_standard}
        os_attrs[:option_names] = option_names unless option_names.nil?
        FactoryGirl.build(:option_set, os_attrs)
      else
        nil
      end
    end

    after(:create) do |question, evaluator|
      if evaluator.add_to_form
        FactoryGirl.create(:questioning, question: question, form: evaluator.add_to_form)
      end
    end
  end
end