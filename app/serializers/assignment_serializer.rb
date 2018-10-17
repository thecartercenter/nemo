# frozen_string_literal: true
class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :mission_id, :role, :new_assignment, :name, :destroy

  def new_assignment
    false
  end

  def name
    Mission.find(mission_id).name
  end

  def destroy
    false
  end
end
