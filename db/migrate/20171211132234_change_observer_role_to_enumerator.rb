class ChangeObserverRoleToEnumerator < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE assignments SET role = 'enumerator' WHERE role = 'observer'")
  end

  def down
    execute("UPDATE assignments SET role = 'observer' WHERE role = 'enumerator'")
  end
end
