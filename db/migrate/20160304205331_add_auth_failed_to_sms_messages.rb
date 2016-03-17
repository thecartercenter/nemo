class AddAuthFailedToSmsMessages < ActiveRecord::Migration
  def change
    add_column :sms_messages, :auth_failed, :boolean, default: false, null: false
  end
end
