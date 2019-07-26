# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: options
#
#  id                :uuid             not null, primary key
#  canonical_name    :string(255)      not null
#  latitude          :decimal(8, 6)
#  longitude         :decimal(9, 6)
#  name_translations :jsonb            not null
#  value             :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid
#
# Indexes
#
#  index_options_on_canonical_name     (canonical_name)
#  index_options_on_mission_id         (mission_id)
#  index_options_on_name_translations  (name_translations) USING gin
#
# Foreign Keys
#
#  options_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :option do
    sequence(:name_en) { |n| "Option #{n}" }
    mission { get_mission }
  end
end
