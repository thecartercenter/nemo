class AddFieldsToSmsMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :sms_messages, :type, :string, null: false
    add_column :sms_messages, :user_id, :integer
    add_column :sms_messages, :broadcast_id, :integer
    add_column :sms_messages, :reply_to_id, :integer

    add_foreign_key :sms_messages, :users
    add_foreign_key :sms_messages, :broadcasts
    add_foreign_key :sms_messages, :sms_messages, column: :reply_to_id
  end
end
