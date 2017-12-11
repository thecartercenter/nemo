class ChangeObserverRoleToEnumerator < ActiveRecord::Migration
  def up
    execute("UPDATE assignments SET role = 'enumerator' WHERE role = 'observer'")
  end

  def down
    execute("UPDATE assignments SET role = 'observer' WHERE role = 'enumerator")
  end
end
