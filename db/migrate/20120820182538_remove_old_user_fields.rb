class RemoveOldUserFields < ActiveRecord::Migration
  def up
    remove_column(:users, :role_id)
    remove_column(:users, :active)
    remove_column(:users, :location_id)
  end

  def down
  end
end
