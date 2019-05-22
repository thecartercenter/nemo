# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: choices
#
#  id         :uuid             not null, primary key
#  latitude   :decimal(8, 6)
#  longitude  :decimal(9, 6)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  answer_id  :uuid             not null
#  option_id  :uuid             not null
#
# Indexes
#
#  index_choices_on_answer_id                (answer_id)
#  index_choices_on_answer_id_and_option_id  (answer_id,option_id) UNIQUE
#  index_choices_on_option_id                (option_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  choices_option_id_fkey  (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :choice do
  end
end
