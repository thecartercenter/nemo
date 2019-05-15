# == Schema Information
#
# Table name: questions
#
#  id                        :uuid             not null, primary key
#  access_level              :string(255)      default("inherit"), not null
#  audio_prompt_content_type :string
#  audio_prompt_file_name    :string
#  audio_prompt_file_size    :integer
#  audio_prompt_updated_at   :datetime
#  auto_increment            :boolean          default(FALSE), not null
#  canonical_name            :text             not null
#  code                      :string(255)      not null
#  hint_translations         :jsonb
#  is_standard               :boolean          default(FALSE), not null
#  key                       :boolean          default(FALSE), not null
#  maximum                   :decimal(15, 8)
#  maxstrictly               :boolean
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
#  questions_original_id_fkey    (original_id => questions.id) ON DELETE => nullify ON UPDATE => restrict
#

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

    mission { is_standard ? nil : get_mission }

    option_set do
      if QuestionType[qtype_name].has_options?
        os_attrs = {
          mission: mission,
          geographic: use_geo_option_set,
          allow_coordinates: use_geo_option_set,
          is_standard: is_standard
        }
        os_attrs[:option_names] = option_names unless option_names.nil?
        build(:option_set, os_attrs)
      end
    end

    after(:create) do |question, evaluator|
      create(:questioning, question: question, form: evaluator.add_to_form) if evaluator.add_to_form
    end
  end
end
