# frozen_string_literal: true

class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :mission_id, :role, :name, :new_record, :_destroy

  def name
    Mission.find(mission_id).name
  end

  def new_record
    object.new_record?
  end
end
