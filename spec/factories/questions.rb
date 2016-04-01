FactoryGirl.define do
  factory :question do
    transient do
      use_multilevel_option_set false
      use_geo_option_set false
      use_large_option_set false
      add_to_form false

      # Optionally specifies the options for the option set.
      option_names nil
    end

    sequence(:code) { |n| "Question#{n}" }
    qtype_name "integer"
    sequence(:name) { |n| "Question Title #{n}" }
    sequence(:hint) { |n| "Question Hint #{n}" }
    mission { is_standard ? nil : get_mission }

    option_set do
      if QuestionType[qtype_name].has_options?
        os_attrs = {
          mission: mission,
          multilevel: use_multilevel_option_set,
          geographic: use_geo_option_set,
          large: use_large_option_set,
          is_standard: is_standard
        }
        os_attrs[:option_names] = option_names unless option_names.nil?
        build(:option_set, os_attrs)
      end
    end

    after(:create) do |question, evaluator|
      FactoryGirl.create(:questioning, question: question, form: evaluator.add_to_form) if evaluator.add_to_form
    end
  end
end
