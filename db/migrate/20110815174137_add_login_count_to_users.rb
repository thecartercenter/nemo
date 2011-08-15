class AddLoginCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :login_count, :integer, :default => 0
  end

  def self.down
    remove_column :users, :login_count
  end
end
