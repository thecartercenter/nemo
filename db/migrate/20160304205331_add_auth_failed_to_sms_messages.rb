class AddAuthFailedToSmsMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :sms_messages, :auth_failed, :boolean, default: false, null: false
  end
end
