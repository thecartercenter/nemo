class AddRoleToConditions < ActiveRecord::Migration
  def change
    add_column :conditions, :role, :string
    execute("UPDATE conditions SET role = 'display'")
    change_column_null :conditions, :role, false
  end
end
