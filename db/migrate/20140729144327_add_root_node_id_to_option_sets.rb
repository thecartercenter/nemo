class AddRootNodeIdToOptionSets < ActiveRecord::Migration[4.2]
  def change
    add_column :option_sets, :root_node_id, :integer
    add_foreign_key :option_sets, :option_nodes, column: :root_node_id
  end
end
