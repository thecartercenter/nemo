# frozen_string_literal: true

class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :mission_id, :mission_name, :role, :new_record, :destroy
  format_keys :lower_camel

  def new_record
    object.new_record?
  end

  def destroy
    object._destroy
  end
end
