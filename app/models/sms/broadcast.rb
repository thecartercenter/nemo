class Sms::Broadcast < Sms::Message
  belongs_to :broadcast, class_name: "::Broadcast", foreign_key: 'broadcast_id'

  def sender
    User::ELMO
  end

  def recipients
    broadcast.recipient_numbers
  end

  def recipient_hashes
    broadcast.sms_recipient_hashes
  end
end
