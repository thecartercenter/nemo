class RenameOptionSettingsToOptionings < ActiveRecord::Migration
  def change
    rename_table :option_settings, :optionings
  end
end
