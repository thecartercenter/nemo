class ConvertIncomingSmsNumbersToArray < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE settings SET incoming_sms_numbers = NULL WHERE incoming_sms_numbers = ''")
    execute(%Q{UPDATE settings SET incoming_sms_numbers =
      CASE WHEN incoming_sms_numbers IS NULL THEN '[]'
      ELSE CONCAT('["', incoming_sms_numbers, '"]') END})
  end
end
