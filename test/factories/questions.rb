FactoryGirl.define do
  factory :question do
    ignore do
      option_names nil
    end

    code {"q#{rand(10000000)}"}
    qtype_name 'integer'
    name 'the question'
    hint 'some info about the question'
    mission { is_standard ? nil : get_mission }

    option_set do
      if QuestionType[qtype_name].has_options?
        opt_set_attribs = {:mission => mission}
        opt_set_attribs[:option_names] = option_names unless option_names.nil?
        FactoryGirl.build(:option_set, opt_set_attribs)
      else
        nil
      end
    end
  end
end