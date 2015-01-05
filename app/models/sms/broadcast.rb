class Sms::Broadcast < Sms::Message
  belongs_to :broadcast, class_name: "::Broadcast", foreign_key: 'broadcast_id'

  def recipients
    broadcast.recipient_numbers
  end

  def recipient_hashes
    recipients.map { |r|
      u = User.where("phone = ? OR phone2 = ?", r, r).first
      {user: u, phone: r}
    }
  end
end
