# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: user_groups
#
#  id         :uuid             not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :uuid             not null
#
# Indexes
#
#  index_user_groups_on_mission_id           (mission_id)
#  index_user_groups_on_name_and_mission_id  (name,mission_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#
# rubocop:enable Metrics/LineLength

# Serializes UserGroups for multiple purposes.
class UserGroupSerializer < ApplicationSerializer
  attributes :id, :name
end
