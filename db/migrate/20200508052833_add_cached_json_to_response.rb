# frozen_string_literal: true

class AddCachedJsonToResponse < ActiveRecord::Migration[5.2]
  def change
    add_column :responses, :cached_json, :jsonb
  end
end
