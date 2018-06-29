class AddLastRequestAtToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :last_request_at, :datetime
  end

  def self.down
    remove_column :users, :last_request_at
  end
end
