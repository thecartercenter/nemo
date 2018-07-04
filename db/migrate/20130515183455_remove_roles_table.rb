class RemoveRolesTable < ActiveRecord::Migration[4.2]
  def up
    # add a new column for the fk replacement
    add_column :assignments, :role, :string

    # populate the new column, taking care to not use the Role class ORM methods, as they're going away
    execute("UPDATE assignments SET role = LOWER((SELECT name FROM roles WHERE id=role_id))")

    #drop_table :roles
    remove_column :assignments, :role_id
  end

  def down
  end
end
