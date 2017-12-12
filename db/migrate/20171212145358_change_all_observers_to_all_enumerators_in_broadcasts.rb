class ChangeAllObserversToAllEnumeratorsInBroadcasts < ActiveRecord::Migration
  def up
    execute("UPDATE broadcasts SET recipient_selection = 'all_enumerators' WHERE recipient_selection = 'all_observers'")
  end

  def down
    execute("UPDATE broadcasts SET recipient_selection = 'all_observers' WHERE recipient_selection = 'all_enumerators'")
  end
end
