class Sms::Broadcast < Sms::Message
  belongs_to :broadcast, class_name: "::Broadcast", foreign_key: 'broadcast_id'

  def recipients
    broadcast.recipient_numbers
  end
end
