class AddNotNullToConditionFks < ActiveRecord::Migration[4.2]
  def change
    execute("DELETE FROM conditions WHERE questioning_id IS NULL OR ref_qing_id IS NULL")
    change_column_null(:conditions, :questioning_id, false)
    change_column_null(:conditions, :ref_qing_id, false)
  end
end
