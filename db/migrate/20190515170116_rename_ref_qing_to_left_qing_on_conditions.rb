# frozen_string_literal: true

class RenameRefQingToLeftQingOnConditions < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :conditions, :form_items
    rename_column :conditions, :ref_qing_id, :left_qing_id
    add_foreign_key :conditions, :form_items, column: :left_qing_id
  end

  def down
    remove_foreign_key :conditions, :form_items
    rename_column :conditions, :left_qing_id, :ref_qing_id
    add_foreign_key :conditions, :form_items, column: :ref_qing_id
  end
end
