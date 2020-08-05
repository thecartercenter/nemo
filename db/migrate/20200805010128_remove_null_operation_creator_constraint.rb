# frozen_string_literal: true

class RemoveNullOperationCreatorConstraint < ActiveRecord::Migration[5.2]
  def change
    change_column_null :operations, :creator_id, true
  end
end
