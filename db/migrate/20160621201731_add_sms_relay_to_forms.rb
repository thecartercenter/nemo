class AddSmsRelayToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :sms_relay, :boolean, default: false, null: false
  end
end
