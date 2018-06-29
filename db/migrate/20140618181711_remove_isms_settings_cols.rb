class RemoveIsmsSettingsCols < ActiveRecord::Migration[4.2]
  def up
    remove_column :settings, :isms_hostname
    remove_column :settings, :isms_username
    remove_column :settings, :isms_password
  end

  def down
  end
end
