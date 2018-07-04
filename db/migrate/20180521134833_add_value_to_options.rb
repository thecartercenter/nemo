# frozen_string_literal: true

# Adds value column to options table
class AddValueToOptions < ActiveRecord::Migration[4.2]
  def change
    add_column :options, :value, :integer, null: true
  end
end
