# frozen_string_literal: true

class AddResponseDeviceId < ActiveRecord::Migration[5.2]
  def change
    add_column :responses, :device_id, :string
  end
end
