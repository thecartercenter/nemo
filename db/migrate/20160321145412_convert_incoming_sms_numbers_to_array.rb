class ConvertIncomingSmsNumbersToArray < ActiveRecord::Migration
  def up
    Setting.find_each do |s|
      s.update_column(:incoming_sms_numbers,
        s.incoming_sms_numbers.blank? ? [] : ["#{s.incoming_sms_numbers}"])
    end
  end
end
