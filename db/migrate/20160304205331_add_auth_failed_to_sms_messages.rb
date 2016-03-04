class AddAuthFailedToSmsMessages < ActiveRecord::Migration
  def change
    add_column :sms_messages, :auth_failed, :boolean
  end
end
