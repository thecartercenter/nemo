class AddNullFalseToOptionNodeOptionSetId < ActiveRecord::Migration
  def change
    change_column_null(:option_nodes, :option_set_id, false)
  end
end
