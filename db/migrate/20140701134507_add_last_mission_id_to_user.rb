class AddLastMissionIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_mission_id, :integer
  end
end
