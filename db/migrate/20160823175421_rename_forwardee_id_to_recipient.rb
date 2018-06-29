class RenameForwardeeIdToRecipient < ActiveRecord::Migration[4.2]
  def up
    rename_column :form_forwardings, :forwardee_id, :recipient_id
    rename_column :form_forwardings, :forwardee_type, :recipient_type
  end
end
