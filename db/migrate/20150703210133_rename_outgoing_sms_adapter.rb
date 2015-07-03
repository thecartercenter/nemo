class RenameOutgoingSmsAdapter < ActiveRecord::Migration
  def change
    rename_column :settings, :outgoing_sms_adapter, :default_outgoing_sms_adapter
  end
end
