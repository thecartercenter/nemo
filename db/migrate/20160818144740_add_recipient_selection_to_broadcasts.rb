class AddRecipientSelectionToBroadcasts < ActiveRecord::Migration[4.2]
  def up
    add_column :broadcasts, :recipient_selection, :string
    execute("UPDATE broadcasts SET recipient_selection='specific'")
    change_column_null :broadcasts, :recipient_selection, false
  end
end
