# frozen_string_literal: true

class AddRepeatCountToQingGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :form_items, :repeat_count, :string
  end
end
