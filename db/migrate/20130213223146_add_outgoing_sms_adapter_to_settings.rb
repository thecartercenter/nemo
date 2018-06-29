class AddOutgoingSmsAdapterToSettings < ActiveRecord::Migration[4.2]
  def up
    add_column :settings, :outgoing_sms_adapter, :string

    # default to intellisms
    Setting.update_all("outgoing_sms_adapter = 'IntelliSms'")
  end
end
