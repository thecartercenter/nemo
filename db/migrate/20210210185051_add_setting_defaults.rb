# frozen_string_literal: true

class AddSettingDefaults < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:settings, :timezone, from: nil, to: "UTC")
    reversible do |dir|
      dir.up do
        execute("UPDATE settings SET incoming_sms_numbers = '[]' WHERE incoming_sms_numbers IS NULL")
        execute("UPDATE settings SET preferred_locales = '[]' WHERE preferred_locales IS NULL")
      end
    end
    change_column_null(:settings, :incoming_sms_numbers, false)
    change_column_null(:settings, :preferred_locales, false)
  end
end
