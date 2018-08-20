# frozen_string_literal: true

class AddCompositeIndexToAssignmentColumns < ActiveRecord::Migration[5.1]
  def change
    add_index :assignments, %i[deleted_at mission_id user_id], unique: true
  end
end
