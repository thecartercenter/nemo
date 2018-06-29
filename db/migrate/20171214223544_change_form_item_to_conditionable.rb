class ChangeFormItemToConditionable < ActiveRecord::Migration[4.2]
  def up
    rename_column :conditions, :questioning_id, :conditionable_id
    add_column :conditions, :conditionable_type, :string
    add_index :conditions, [:conditionable_type, :conditionable_id]
    Condition.reset_column_information
    Condition.update_all(:conditionable_type => "FormItem")
  end

  def down
    rename_column :conditions, :conditionable_id, :questioning_id
    remove_column :conditions, :conditionable_type
  end
end
