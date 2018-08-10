# frozen_string_literal: true

class DeleteAssignmentsWithDuplicateMissionAndUser < ActiveRecord::Migration[5.1]
  def up
    duplicates = []
    dup_attrs = Assignment.select(:mission_id, :user_id).group(:mission_id, :user_id).having("count(*) > 1")

    dup_attrs.each do |dup|
      dup_assignments = Assignment.where(mission_id: dup.mission_id, user_id: dup.user_id)
      duplicates << dup_assignments.first
    end

    duplicates.map(&:destroy)
  end

  def down
  end
end
