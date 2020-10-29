# frozen_string_literal: true

class RemoveUuidFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :uuid, :string
  end
end
