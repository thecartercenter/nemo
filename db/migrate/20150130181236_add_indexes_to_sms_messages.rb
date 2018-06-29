class AddIndexesToSmsMessages < ActiveRecord::Migration[4.2]
  def change
    add_index :sms_messages, :type
    add_index :sms_messages, :to
    add_index :sms_messages, :from
    add_index :sms_messages, :created_at
    add_index :users, :name
  end
end
