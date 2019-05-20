FactoryGirl.define do
  factory :question do
    transient do
      use_geo_option_set false
      multilingual false
      with_user_locale false
      add_to_form false

      # Optionally specifies the options for the option set.
      option_names nil
    end

    qtype_name "integer"
    sequence(:code) { |n| "#{qtype_name.camelize}Q#{n}" }

    sequence(:name_translations) do |n|
      name = "#{qtype_name.titleize} Question Title #{n}"
      translations = {en: name}
      translations[:fr] = "fr: #{name}" if multilingual
      translations[:rw] = "rw: #{name}" if with_user_locale
      translations
    end
    name { name_translations[:en] }

    sequence(:hint_translations) do |n|
      hint = "Question Hint #{n}"
      translations = {en: hint}
      translations[:fr] = "fr: #{hint}" if multilingual
      translations[:rw] = "rw: #{hint}" if with_user_locale
      translations
    end
    hint { hint_translations[:en] } # needed for some i18n specs

    mission { get_mission }

    option_set do
      if QuestionType[qtype_name].has_options?
        os_attrs = {mission: mission, geographic: use_geo_option_set, allow_coordinates: use_geo_option_set}
        os_attrs[:option_names] = option_names unless option_names.nil?
        build(:option_set, os_attrs)
      end
    end

    after(:create) do |question, evaluator|
      create(:questioning, question: question, form: evaluator.add_to_form) if evaluator.add_to_form
    end

    trait :standard do
      mission { nil }
    end
  end
end
