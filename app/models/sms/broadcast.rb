class Sms::Broadcast < Sms::Message
  belongs_to :broadcast, class_name: "::Broadcast", foreign_key: 'broadcast_id'

  def sender
    User::ELMO
  end

  def recipients
    broadcast.recipient_numbers
  end

  def recipient_hashes
    @recipient_hashes ||= recipients.map { |r|
      u = User.by_phone(r)
      {user: u, phone: r}
    }
  end
end
