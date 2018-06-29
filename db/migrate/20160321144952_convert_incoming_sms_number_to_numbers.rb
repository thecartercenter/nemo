class ConvertIncomingSmsNumberToNumbers < ActiveRecord::Migration[4.2]
  def change
    change_column :settings, :incoming_sms_number, :text
    rename_column :settings, :incoming_sms_number, :incoming_sms_numbers
  end
end
