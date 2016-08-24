class RenameSpecificUsersToSpecific < ActiveRecord::Migration
  def up
    execute("UPDATE broadcasts SET recipient_selection = 'specific'
      WHERE recipient_selection = 'specific_users'")
  end
end
