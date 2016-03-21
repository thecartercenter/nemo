class SetNotNullForIncomingNumbers < ActiveRecord::Migration
  def change
    change_column_null :settings, :incoming_sms_numbers, false
  end
end
