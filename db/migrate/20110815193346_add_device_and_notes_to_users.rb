class AddDeviceAndNotesToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :device, :string
    add_column :users, :notes, :text
  end

  def self.down
    remove_column :users, :notes
    remove_column :users, :device
  end
end
