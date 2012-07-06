class RemoveDeviceFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :device
  end

  def down
    add_column :users, :device, :string
  end
end
