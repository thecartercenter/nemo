class RemoveRoleFromConditions < ActiveRecord::Migration[4.2]
  def change
    remove_column :conditions, :role
  end
end
