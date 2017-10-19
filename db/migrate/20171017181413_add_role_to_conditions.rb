class AddRoleToConditions < ActiveRecord::Migration
  def up
    add_column :conditions, :role, :string
    execute("UPDATE conditions SET role = 'display'")
    change_column_null :conditions, :role, false
  end

  def down
    remove_column :conditions, :role
  end
end
