class AddIndexToSmsBody < ActiveRecord::Migration
  def change
    add_index :sms_messages, :body, :length => 160
  end
end
