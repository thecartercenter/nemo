# frozen_string_literal: true

class DeleteAssignmentsWithDuplicateMissionAndUser < ActiveRecord::Migration[5.1]
  def up
    dup_attrs = Assignment.select(:mission_id, :user_id).group(:mission_id, :user_id).having("count(*) > 1")

    dup_attrs.each do |dup|
      Assignment.where(mission_id: dup.mission_id, user_id: dup.user_id)[1..-1].each(&:destroy)
    end
  end

  def down
  end
end
