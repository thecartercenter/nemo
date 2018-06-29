class NormalizeIncomingNumbers < ActiveRecord::Migration[4.2]
  def up
    Setting.find_each do |s|
      s.incoming_sms_numbers = s.incoming_sms_numbers.map do |n|
        PhoneNormalizer.normalize(n)
      end.compact
      s.save(validate: false)
    end
  end
end
