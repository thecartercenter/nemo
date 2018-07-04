class AddLoginCountToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :login_count, :integer, :default => 0
  end

  def self.down
    remove_column :users, :login_count
  end
end
