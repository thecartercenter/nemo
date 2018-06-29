class AddIndexToSmsBody < ActiveRecord::Migration[4.2]
  def change
    add_index :sms_messages, :body, :length => 160
  end
end
