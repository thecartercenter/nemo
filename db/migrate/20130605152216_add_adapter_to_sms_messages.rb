class AddAdapterToSmsMessages < ActiveRecord::Migration
  def change
    add_column :sms_messages, :adapter_name, :string
  end
end
