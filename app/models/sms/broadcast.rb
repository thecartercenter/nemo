class Sms::Broadcast < Sms::Message
  belongs_to :broadcast, class_name: "::Broadcast", foreign_key: 'broadcast_id'

  def sender
    User::ELMO
  end

  def recipients
    broadcast.recipient_numbers
  end

  # Returns a set of hashes of form {user: x, phone: y} for recipients.
  # options[:max] - The max number to return (defaults to all).
  def recipient_hashes(options = {})
    broadcast.sms_recipient_hashes(options)
  end
end
