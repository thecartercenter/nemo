class RemoveRoleFromConditions < ActiveRecord::Migration
  def change
    remove_column :conditions, :role
  end
end
