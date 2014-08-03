class ChangeOptionNodeOptionSetIdNullConstraint < ActiveRecord::Migration
  def up
    change_column :option_nodes, :option_set_id, :integer, :null => true
  end

  def down
  end
end
