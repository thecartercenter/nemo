FactoryGirl.define do
  factory :form do
    ignore do
      question_types []
      use_multilevel_option_set false

      # optionally specifies the options for the option set of the first select type question on the form
      option_names nil
    end

    mission { is_standard ? nil : get_mission }
    sequence(:name) { |n| "Sample Form #{n}" }

    questionings do
      found_select = false
      question_types.each_with_index.map do |qt, idx|
        question_attribs = {
          code: "q#{rand(100000)}",
          qtype_name: qt,
          mission: mission,
          use_multilevel_option_set: use_multilevel_option_set
        }

        # assign the options to the question if appropriate
        if QuestionType[qt].has_options? && !found_select && !option_names.nil?
          question_attribs[:option_names] = option_names
          found_select = true
        end

        # build the questioning
        FactoryGirl.build(:questioning,
          :mission => mission,
          :form => nil, # Will be filled in when saved
          :question => FactoryGirl.build(:question, question_attribs))
      end
    end

    # A form with different question types.
    factory :sample_form do
      questionings do
        [
          # Single level select_one question.
          build(:questioning, mission: mission, form: nil,
            question: build(:question, mission: mission, qtype_name: 'select_one', option_set: build(:option_set))),

          # Multilevel select_one question.
          build(:questioning, mission: mission, form: nil,
            question: build(:question, mission: mission, qtype_name: 'select_one', option_set: build(:option_set, multi_level: true))),

          # Integer question.
          build(:questioning, mission: mission, form: nil,
            question: build(:question, mission: mission, qtype_name: 'integer'))
        ]
      end
    end
  end
end
