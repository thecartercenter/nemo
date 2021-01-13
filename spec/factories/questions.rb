# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: questions
#
#  id                        :uuid             not null, primary key
#  access_level              :string(255)      default("inherit"), not null
#  auto_increment            :boolean          default(FALSE), not null
#  canonical_name            :text             not null
#  code                      :string(255)      not null
#  hint_translations         :jsonb
#  key                       :boolean          default(FALSE), not null
#  maximum                   :decimal(15, 8)
#  maxstrictly               :boolean
#  media_prompt_content_type :string
#  media_prompt_file_name    :string
#  media_prompt_file_size    :integer
#  media_prompt_updated_at   :datetime
#  metadata_type             :string
#  minimum                   :decimal(15, 8)
#  minstrictly               :boolean
#  name_translations         :jsonb            not null
#  qtype_name                :string(255)      not null
#  reference                 :string
#  standard_copy             :boolean          default(FALSE), not null
#  text_type_for_sms         :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  mission_id                :uuid
#  option_set_id             :uuid
#  original_id               :uuid
#
# Indexes
#
#  index_questions_on_mission_id           (mission_id)
#  index_questions_on_mission_id_and_code  (mission_id,code) UNIQUE
#  index_questions_on_option_set_id        (option_set_id)
#  index_questions_on_original_id          (original_id)
#  index_questions_on_qtype_name           (qtype_name)
#
# Foreign Keys
#
#  questions_mission_id_fkey     (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  questions_option_set_id_fkey  (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :question do
    transient do
      use_geo_option_set { false }
      multilingual { false }
      with_user_locale { false }
      add_to_form { false }

      # Optionally specifies the options for the option set.
      option_names { nil }

      # Optionally specifies a media_prompt attachment.
      filename { nil }
      fixture { media_fixture(filename) if filename }
    end

    # Attached after build.
    media_prompt { nil }

    after(:build) do |obj, evaluator|
      if evaluator.fixture
        obj.media_prompt.attach(io: evaluator.fixture, filename: File.basename(evaluator.fixture))
      end
    end

    qtype_name { "integer" }
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
