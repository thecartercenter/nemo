class RenameOutgoingSmsAdapter < ActiveRecord::Migration[4.2]
  def change
    rename_column :settings, :outgoing_sms_adapter, :default_outgoing_sms_adapter
  end
end
