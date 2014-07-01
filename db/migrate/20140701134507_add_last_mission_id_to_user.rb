class AddLastMissionIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_mission_id, :integer
  end
end
