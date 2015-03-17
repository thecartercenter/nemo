class AddIndexesToSmsMessages < ActiveRecord::Migration
  def change
    add_index :sms_messages, :type
    add_index :sms_messages, :to
    add_index :sms_messages, :from
    add_index :sms_messages, :created_at
    add_index :users, :name
  end
end
