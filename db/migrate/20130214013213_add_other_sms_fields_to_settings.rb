class AddOtherSmsFieldsToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :outgoing_sms_username, :string
    add_column :settings, :outgoing_sms_password, :string
    add_column :settings, :outgoing_sms_extra, :string
  end
end
