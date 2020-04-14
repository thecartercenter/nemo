# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: tags
#
#  id         :uuid             not null, primary key
#  name       :string(64)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :uuid
#
# Indexes
#
#  index_tags_on_mission_id           (mission_id)
#  index_tags_on_name_and_mission_id  (name,mission_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    mission
  end
end
