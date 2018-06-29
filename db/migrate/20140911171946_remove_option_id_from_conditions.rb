class RemoveOptionIdFromConditions < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key :conditions, :option
    remove_column :conditions, :option_id
  end

  def down
    add_column :conditions, :option_id, :integer
  end
end
