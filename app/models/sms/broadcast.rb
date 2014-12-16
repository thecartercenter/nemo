class Sms::Broadcast < Sms::Message
  belongs_to :broadcast

  def recipients
    broadcast.sms_numbers
  end
end
