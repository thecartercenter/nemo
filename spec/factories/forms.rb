def create_questioning(qtype_name_or_question, form, parent, evaluator)
  question = if qtype_name_or_question.is_a?(Question)
    qtype_name_or_question
  else
    qtype_name = qtype_name_or_question
    q_attribs = {
      qtype_name: qtype_name == 'multi_level_select_one' ? 'select_one' : qtype_name,
      mission: form.mission,
      use_multilevel_option_set: qtype_name == 'multi_level_select_one',
      is_standard: form.is_standard?
    }

    if evaluator.option_set
      q_attribs[:option_set] = evaluator.option_set
    elsif evaluator.option_names
      q_attribs[:option_names] = evaluator.option_names
    end

    build(:question, q_attribs)
  end

  form.questionings << create(:questioning,
    mission: form.mission,
    parent: parent,
    form: form,
    question: question)
end

# Only works with create
FactoryGirl.define do
  factory :form do
    transient do
      # Can specify questions or question_types. questions takes precedence.
      questions []
      question_types []

      # Args to forward to question factory.
      option_set nil
      option_names nil
    end

    mission { is_standard ? nil : get_mission }
    sequence(:name) { |n| "Sample Form #{n}" }

    after(:create) do |form, evaluator|
      form.create_root_group!(form: form)
      form.save!

      items = evaluator.questions.present? ? evaluator.questions : evaluator.question_types
      # Build questions.
      items.each do |item|
        if item.is_a?(Array)
          group = QingGroup.create!(parent: form.root_group, form: form, group_name_en: 'Group Name')
          item.each { |q| create_questioning(q, form, group, evaluator) }
        else
          create_questioning(item, form, form.root_group, evaluator)
        end
      end
    end

    # A form with different question types.
    # We hardcode names to make expectations easier, since we assume no more than one sample form per test.
    # Used in the feature specs
    factory :sample_form do
      name 'Sample Form'

      after(:create) do |form, evaluator|
        form.questionings do
          [
            # Single level select_one question.
            create(:questioning, mission: mission, form: form, parent: form.root_group,
              question: create(:question, mission: mission, name: 'Question 1', hint: 'Hint 1',
                qtype_name: 'select_one', option_set: create(:option_set, name: 'Set 1'))),

            # Multilevel select_one question.
            create(:questioning, mission: mission, form: form, parent: form.root_group,
              question: create(:question, mission: mission, name: 'Question 2', hint: 'Hint 2',
                qtype_name: 'select_one', option_set: create(:option_set, name: 'Set 2', multi_level: true))),

            # Integer question.
            create(:questioning, mission: mission, form: form, parent: form.root_group,
              question: create(:question, mission: mission, name: 'Question 3', hint: 'Hint 3',
                qtype_name: 'integer'))
          ]
        end
      end
    end
  end
end
