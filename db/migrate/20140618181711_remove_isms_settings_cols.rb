class RemoveIsmsSettingsCols < ActiveRecord::Migration
  def up
    remove_column :settings, :isms_hostname
    remove_column :settings, :isms_username
    remove_column :settings, :isms_password
  end

  def down
  end
end
