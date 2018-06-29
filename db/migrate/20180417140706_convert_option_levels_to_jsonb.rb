# frozen_string_literal: true

# Convert option_levels "JSON as text" column to JSONB for easier querying.
class ConvertOptionLevelsToJsonb < ActiveRecord::Migration[4.2]
  def up
    execute("ALTER TABLE option_sets ADD COLUMN level_names_jsonb jsonb")
    execute("UPDATE option_sets set level_names_jsonb = level_names::jsonb")
    execute("ALTER TABLE option_sets DROP COLUMN level_names")
    execute("ALTER TABLE option_sets RENAME COLUMN level_names_jsonb TO level_names")
  end
end
