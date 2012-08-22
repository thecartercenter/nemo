class AddCurrentMissionIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_mission_id, :integer
  end
end
