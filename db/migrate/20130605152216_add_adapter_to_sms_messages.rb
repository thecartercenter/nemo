class AddAdapterToSmsMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :sms_messages, :adapter_name, :string
  end
end
