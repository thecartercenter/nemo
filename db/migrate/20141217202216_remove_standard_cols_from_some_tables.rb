class RemoveStandardColsFromSomeTables < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key(:questionings, :standard)
    remove_foreign_key(:conditions, :standard)
    remove_foreign_key(:option_nodes, :standard)
    remove_foreign_key(:options, :standard)
    add_index(:questionings, :mission_id)
    add_index(:conditions, :mission_id)
    add_index(:options, :mission_id)
    remove_index(:questionings, [:mission_id, :standard_id])
    remove_index(:conditions, [:mission_id, :standard_id])
    remove_index(:options, [:mission_id, :standard_id])
    remove_column(:questionings, :is_standard)
    remove_column(:questionings, :standard_id)
    remove_column(:conditions, :is_standard)
    remove_column(:conditions, :standard_id)
    remove_column(:option_nodes, :is_standard)
    remove_column(:option_nodes, :standard_id)
    remove_column(:options, :is_standard)
    remove_column(:options, :standard_id)
    remove_column(:tags, :is_standard)
    remove_column(:tags, :standard_id)
    remove_column(:taggings, :is_standard)
    remove_column(:taggings, :standard_id)
  end

  def down
  end
end
