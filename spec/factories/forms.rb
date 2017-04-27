def create_questioning(qtype_name_or_question, form, parent = nil, evaluator = nil)
  parent ||= form.root_group # root if not specified
  question = if qtype_name_or_question.is_a?(Question)
    qtype_name_or_question
  else
    pseudo_qtype_name = qtype_name_or_question

    qtype_name = case pseudo_qtype_name
    when "multilevel_select_one", "geo_select_one", "geo_multilevel_select_one", "large_select_one",
      "select_one_as_text_for_sms", "multilevel_select_one_as_text_for_sms", "select_one_with_appendix_for_sms"
      "select_one"
    when "select_multiple_with_appendix_for_sms", "large_select_multiple"
      "select_multiple"
    when "multilingual_text", "multilingual_text_with_user_locale"
      "text"
    else
      pseudo_qtype_name
    end

    q_attribs = {
      qtype_name: qtype_name,
      mission: form.mission,
      use_multilevel_option_set: !!(pseudo_qtype_name =~ /multilevel_select_one/),
      use_geo_option_set: !!(pseudo_qtype_name =~ /geo/),
      use_large_option_set: !!(pseudo_qtype_name =~ /large/),
      multilingual: !!(pseudo_qtype_name =~ /multilingual/),
      with_user_locale: !!(pseudo_qtype_name =~ /with_user_locale/),
      is_standard: form.is_standard?
    }

    if evaluator.try(:option_set)
      q_attribs[:option_set] = evaluator.option_set
    elsif evaluator.try(:option_names)
      q_attribs[:option_names] = evaluator.option_names
    end

    question = build(:question, q_attribs)
    question.option_set.sms_guide_formatting = "treat_as_text" if pseudo_qtype_name =~ /as_text_for_sms/
    question.option_set.sms_guide_formatting = "appendix" if pseudo_qtype_name =~ /with_appendix_for_sms/
    question
  end

  questioning = create(:questioning,
    mission: form.mission,
    parent: parent,
    form: form,
    question: question)

  form.questionings << questioning
  questioning
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

    authenticate_sms false
    mission { is_standard ? nil : get_mission }
    sequence(:name) { |n| "Sample Form #{n}" }

    after(:create) do |form, evaluator|
      form.create_root_group!(form: form)
      form.save!

      items = evaluator.questions.present? ? evaluator.questions : evaluator.question_types
      # Build questions.
      items.each do |item|
        if item.is_a?(Hash) && item.key?(:repeating)
          item = item[:repeating]
          group = QingGroup.create!(parent: form.root_group, form: form, group_name_en: "Group Name", group_hint_en: "Group Hint", repeatable: true)
          item.each { |q| create_questioning(q, form, group, evaluator) }
        elsif item.is_a?(Array)
          group = QingGroup.create!(parent: form.root_group, form: form, group_name_en: "Group Name", group_hint_en: "Group Hint")
          item.each { |q| create_questioning(q, form, group, evaluator) }
        else
          create_questioning(item, form, form.root_group, evaluator)
        end
      end
    end

    trait :published do
      after(:create) do |form|
        form.publish!
      end
    end

    # DO NOT USE, USE FORM ABOVE
    # A form with different question types.
    # We hardcode names to make expectations easier, since we assume no more than one sample form per test.
    # Used in the feature specs
    factory :sample_form do
      name "Sample Form"

      after(:create) do |form, evaluator|
        form.questionings do
          [
            # Single level select_one question.
            create(:questioning, mission: mission, form: form, parent: form.root_group,
              question: create(:question, mission: mission, name: "Question 1", hint: "Hint 1",
                qtype_name: "select_one", option_set: create(:option_set, name: "Set 1"))),

            # Multilevel select_one question.
            create(:questioning, mission: mission, form: form, parent: form.root_group,
              question: create(:question, mission: mission, name: "Question 2", hint: "Hint 2",
                qtype_name: "select_one", option_set: create(:option_set, name: "Set 2", multilevel: true))),

            # Integer question.
            create(:questioning, mission: mission, form: form, parent: form.root_group,
              question: create(:question, mission: mission, name: "Question 3", hint: "Hint 3",
                qtype_name: "integer"))
          ]
        end
      end
    end
  end
end
