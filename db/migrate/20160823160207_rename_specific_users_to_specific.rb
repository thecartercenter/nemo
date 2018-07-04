class RenameSpecificUsersToSpecific < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE broadcasts SET recipient_selection = 'specific'
      WHERE recipient_selection = 'specific_users'")
  end
end
