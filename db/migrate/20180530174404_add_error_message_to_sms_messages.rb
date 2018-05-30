class AddErrorMessageToSmsMessages < ActiveRecord::Migration
  def change
    add_column :sms_messages, :error_message, :string
  end
end
