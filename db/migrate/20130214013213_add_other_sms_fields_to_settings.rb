class AddOtherSmsFieldsToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :outgoing_sms_username, :string
    add_column :settings, :outgoing_sms_password, :string
    add_column :settings, :outgoing_sms_extra, :string    
  end
end
