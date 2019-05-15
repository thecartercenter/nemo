# frozen_string_literal: true

class AddRightQingIdToConditions < ActiveRecord::Migration[5.2]
  def change
    add_column :conditions, :right_qing_id, :uuid, index: true
    add_foreign_key :conditions, :form_items, column: :right_qing_id
  end
end
