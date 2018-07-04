# frozen_string_literal: true

# A theme flag file may have been created when the new theme changes were first deployed via
# the theme:migrate task run by assets:precompile. If it exists, we need to update the DB
# (which already has the theme setting by now) to set it to the proper value for all missions.
class RespectThemeFlagFile < ActiveRecord::Migration[4.2]
  def up
    path = Rails.root.join("tmp", "theme_flag")

    # Since the old default theme was elmo, that's what we default to here,
    # even though the _column_ default is nemo.
    theme = File.exist?(path) ? File.read(path) : "elmo"

    Setting.update_all(theme: theme)
  end
end
