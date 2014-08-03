class AddRootNodeIdToOptionSets < ActiveRecord::Migration
  def change
    add_column :option_sets, :root_node_id, :integer
    add_foreign_key :option_sets, :option_nodes, column: :root_node_id
  end
end
