# frozen_string_literal: true

class AddQingHidden < ActiveRecord::Migration[5.2]
  def change
    add_column :form_items, :hidden, :boolean, null: false, default: false
  end
end
