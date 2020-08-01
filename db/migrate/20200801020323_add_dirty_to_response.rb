# frozen_string_literal: true

class AddDirtyToResponse < ActiveRecord::Migration[5.2]
  def change
    add_column :responses, :dirty_json, :boolean, default: true, null: false
  end
end
