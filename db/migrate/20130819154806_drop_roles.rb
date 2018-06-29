class DropRoles < ActiveRecord::Migration[4.2]
  def up
  	drop_table :roles
  end

  def down
  end
end
