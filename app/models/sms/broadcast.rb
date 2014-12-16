class Sms::Broadcast < Sms::Message
  belongs_to :broadcast

  def recipients
    broadcast.recipient_numbers
  end
end
