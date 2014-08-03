class AddAncestryDepthToOptionNodes < ActiveRecord::Migration
  def change
    add_column :option_nodes, :ancestry_depth, :integer, default: 0
  end
end
