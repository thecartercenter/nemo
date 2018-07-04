class AddIncomingSmsNumberToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :incoming_sms_number, :string
  end
end
