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
#  user_groups_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#

class UserGroupSerializer < ActiveModel::Serializer
  attributes :id, :text

  def text
    object.name
  end
end
