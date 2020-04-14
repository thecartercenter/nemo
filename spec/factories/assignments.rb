# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: assignments
#
#  id         :uuid             not null, primary key
#  role       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_assignments_on_mission_id              (mission_id)
#  index_assignments_on_mission_id_and_user_id  (mission_id,user_id) UNIQUE
#  index_assignments_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#  fk_rails_...  (user_id => users.id)
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :assignment do
    mission
    role "enumerator"
  end
end
