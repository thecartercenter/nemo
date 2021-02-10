# frozen_string_literal: true

class AddSettingDefaults < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:settings, :timezone, from: nil, to: "UTC")
    change_column_null(:settings, :incoming_sms_numbers, false)
    change_column_null(:settings, :preferred_locales, false)
  end
end
