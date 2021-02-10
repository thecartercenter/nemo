# frozen_string_literal: true

class ConvertSettingsToJsonb < ActiveRecord::Migration[6.1]
  def up
    execute("ALTER TABLE settings ADD COLUMN preferred_locales_jsonb jsonb DEFAULT '[\"en\"]'::jsonb")
    execute("UPDATE settings set preferred_locales_jsonb = preferred_locales::jsonb")
    execute("ALTER TABLE settings DROP COLUMN preferred_locales")
    execute("ALTER TABLE settings RENAME COLUMN preferred_locales_jsonb TO preferred_locales")

    execute("ALTER TABLE settings ADD COLUMN incoming_sms_numbers_jsonb jsonb DEFAULT '[]'::jsonb")
    execute("UPDATE settings set incoming_sms_numbers_jsonb = incoming_sms_numbers::jsonb")
    execute("ALTER TABLE settings DROP COLUMN incoming_sms_numbers")
    execute("ALTER TABLE settings RENAME COLUMN incoming_sms_numbers_jsonb TO incoming_sms_numbers")
  end
end
