class RemoveDeviceFromUsers < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :device
  end

  def down
    add_column :users, :device, :string
  end
end
