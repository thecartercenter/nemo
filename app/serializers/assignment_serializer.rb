class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :mission_id, :role
end
