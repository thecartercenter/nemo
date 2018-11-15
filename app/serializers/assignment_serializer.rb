# frozen_string_literal: true

class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :mission_id, :role, :name, :new_record, :_destroy
  format_keys :lower_camel

  def name
    Mission.find(mission_id).name
  end

  def new_record
    object.new_record?
  end
end
