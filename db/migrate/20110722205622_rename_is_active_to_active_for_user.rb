class RenameIsActiveToActiveForUser < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :users, :is_active, :active
  end

  def self.down
  end
end
