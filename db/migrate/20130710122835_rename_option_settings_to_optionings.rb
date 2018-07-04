class RenameOptionSettingsToOptionings < ActiveRecord::Migration[4.2]
  def change
    rename_table :option_settings, :optionings
  end
end
