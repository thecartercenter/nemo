# frozen_string_literal: true

class AddNotesToOperation < ActiveRecord::Migration[5.2]
  def change
    add_column :operations, :notes, :string, limit: 255
  end
end
