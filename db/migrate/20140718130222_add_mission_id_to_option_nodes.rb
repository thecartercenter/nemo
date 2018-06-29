class AddMissionIdToOptionNodes < ActiveRecord::Migration[4.2]
  def change
    add_column :option_nodes, :mission_id, :integer
    add_foreign_key :option_nodes, :missions
  end
end
