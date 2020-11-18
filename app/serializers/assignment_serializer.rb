# frozen_string_literal: true

# rubocop:disable Layout/LineLength
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
#  assignments_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  assignments_user_id_fkey     (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# Serializes user assignments
class AssignmentSerializer < ApplicationSerializer
  fields :id, :mission_id, :mission_name, :role
  field :new_record?, name: :new_record
  field :_destroy, name: :destroy
end
