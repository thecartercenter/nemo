class AddSmsRelayToForms < ActiveRecord::Migration
  def change
    add_column :forms, :sms_relay, :boolean, default: false, null: false
  end
end
