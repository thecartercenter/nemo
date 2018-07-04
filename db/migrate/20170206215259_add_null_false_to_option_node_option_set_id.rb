class AddNullFalseToOptionNodeOptionSetId < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:option_nodes, :option_set_id, false)
  end
end
