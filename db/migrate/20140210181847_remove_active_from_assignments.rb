class RemoveActiveFromAssignments < ActiveRecord::Migration[4.2]
  def up
    remove_column :assignments, :active
  end

  def down
    add_column :assignments, :active, :boolean
  end
end
