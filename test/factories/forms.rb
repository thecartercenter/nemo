FactoryGirl.define do
  factory :form do
    ignore do
      question_types []

      # optionally specifies the options for the option set of the first select type question on the form
      option_names nil
    end

    mission { is_standard ? nil : get_mission }

    name {"some form #{rand(1000000)}"}

    questionings do
      found_select = false
      question_types.each_with_index.map do |qt, idx|
        question_attribs = {:code => "q#{rand(100000)}", :qtype_name => qt}

        # assign the options to the question if appropriate
        if QuestionType[qt].has_options? && !found_select && !option_names.nil?
          question_attribs[:option_names] = option_names
          found_select = true
        end

        # build the questioning
        FactoryGirl.build(:questioning, :question => FactoryGirl.build(:question, question_attribs))
      end
    end
  end
end
