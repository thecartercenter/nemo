# frozen_string_literal: true

class AddAPIKeyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_key, :string
    add_index :users, :api_key, unique: true
  end
end