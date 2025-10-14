# frozen_string_literal: true

class AddApiKeyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_key, :string
    add_index :users, :api_key, unique: true
  end
end