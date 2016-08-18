class AddRecipientSelectionToBroadcasts < ActiveRecord::Migration
  def up
    add_column :broadcasts, :recipient_selection, :string
    execute("UPDATE broadcasts SET recipient_selection='specific_users'")
    change_column_null :broadcasts, :recipient_selection, false
  end
end
