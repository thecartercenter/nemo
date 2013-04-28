class AddIncomingSmsNumberToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :incoming_sms_number, :string
  end
end
