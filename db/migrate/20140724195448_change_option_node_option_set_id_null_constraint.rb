class ChangeOptionNodeOptionSetIdNullConstraint < ActiveRecord::Migration[4.2]
  def up
    change_column :option_nodes, :option_set_id, :integer, :null => true
  end

  def down
  end
end
