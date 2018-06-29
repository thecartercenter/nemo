class AddCurrentMissionIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_mission_id, :integer
  end
end
