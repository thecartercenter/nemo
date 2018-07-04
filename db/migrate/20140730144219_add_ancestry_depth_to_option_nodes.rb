class AddAncestryDepthToOptionNodes < ActiveRecord::Migration[4.2]
  def change
    add_column :option_nodes, :ancestry_depth, :integer, default: 0
  end
end
