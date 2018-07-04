class RemoveCurrentMissionIdFromUsers < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key(:users, :current_mission)
    remove_column :users, :current_mission_id
  end

  def down
    add_column :users, :current_mission_id, :integer
  end
end
