# frozen_string_literal: true

class RenameQingHiddenToDisabled < ActiveRecord::Migration[5.2]
  def change
    rename_column :form_items, :hidden, :disabled
  end
end
