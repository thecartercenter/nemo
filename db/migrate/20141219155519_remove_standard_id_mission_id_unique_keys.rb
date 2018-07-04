class RemoveStandardIdMissionIdUniqueKeys < ActiveRecord::Migration[4.2]
  def up
    remove_index :forms, [:mission_id, :standard_id]
    remove_index :questions, [:mission_id, :standard_id]
    add_index :option_sets, [:mission_id]
    remove_index :option_sets, [:mission_id, :standard_id]
  end

  def down
  end
end
