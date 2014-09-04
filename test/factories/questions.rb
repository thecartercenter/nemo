FactoryGirl.define do
  factory :question do
    ignore do
      option_names nil
      use_multilevel_option_set false
    end

    sequence(:code) { |n| "Question#{n}" }
    qtype_name 'integer'
    sequence(:name) { |n| "Question Title #{n}" }
    sequence(:hint) { |n| "Question Hint #{n}" }
    mission { is_standard ? nil : get_mission }

    option_set do
      if QuestionType[qtype_name].has_options?
        opt_set_attribs = {mission: mission, multi_level: use_multilevel_option_set}
        opt_set_attribs[:option_names] = option_names unless option_names.nil?
        FactoryGirl.build(:option_set, opt_set_attribs)
      else
        nil
      end
    end
  end
end