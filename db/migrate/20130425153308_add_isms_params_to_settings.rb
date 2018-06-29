class AddIsmsParamsToSettings < ActiveRecord::Migration[4.2]
  def change
    rename_column :settings, :outgoing_sms_username, :intellisms_username
    rename_column :settings, :outgoing_sms_password, :intellisms_password
    remove_column :settings, :outgoing_sms_extra
    add_column :settings, :isms_hostname, :string
    add_column :settings, :isms_username, :string
    add_column :settings, :isms_password, :string
  end
end