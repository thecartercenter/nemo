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
        qtype = QuestionType[qt == 'multi_level_select_one' ? 'select_one' : qt]

        question_attribs = {
          qtype_name: qtype.name,
          mission: mission,
          use_multilevel_option_set: use_multilevel_option_set || qt == 'multi_level_select_one'
        }

        # assign the options to the question if appropriate
        if qtype.has_options? && !found_select && !option_names.nil?
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
    # We hardcode names to make expectations easier, since we assume no more than one sample form per test.
    factory :sample_form do
      name 'Sample Form'
      questionings do
        [
          # Single level select_one question.
          build(:questioning, mission: mission, form: nil,
            question: build(:question, mission: mission, name: 'Question 1', hint: 'Hint 1',
              qtype_name: 'select_one', option_set: build(:option_set, name: 'Set 1'))),

          # Multilevel select_one question.
          build(:questioning, mission: mission, form: nil,
            question: build(:question, mission: mission, name: 'Question 2', hint: 'Hint 2',
              qtype_name: 'select_one', option_set: build(:option_set, name: 'Set 2', multi_level: true))),

          # Integer question.
          build(:questioning, mission: mission, form: nil,
            question: build(:question, mission: mission, name: 'Question 3', hint: 'Hint 3',
              qtype_name: 'integer'))
        ]
      end
    end
  end
end
