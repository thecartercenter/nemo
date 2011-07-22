class RenameIsActiveToActiveForUser < ActiveRecord::Migration
  def self.up
    rename_column :users, :is_active, :active
  end

  def self.down
  end
end
