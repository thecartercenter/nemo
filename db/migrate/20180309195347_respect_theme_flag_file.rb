# frozen_string_literal: true

# A theme flag file may have been created when the new theme changes were first deployed via
# the theme:migrate task run by assets:precompile. If it exists, we need to update the DB
# (which already has the theme setting by now) to set it to the proper value for all missions.
class RespectThemeFlagFile < ActiveRecord::Migration
  def up
    path = Rails.root.join("tmp", "theme_flag")
    Setting.update_all(theme: File.read(path)) if File.exist?(path)
  end
end
