# frozen_string_literal: true

class RemoveNullRejectionMsgConstraint < ActiveRecord::Migration[5.2]
  def change
    change_column_null :constraints, :rejection_msg_translations, true
  end
end
