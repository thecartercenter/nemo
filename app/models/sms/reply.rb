class Sms::Reply < Sms::Message
  # Reference to the incoming message.
  belongs_to :reply_to, class_name: "Sms::Incoming"

  def sender
    User::ELMO
  end

  def recipient_count
    1
  end

  def recipient_numbers
    [to]
  end

  def recipient_hashes(options = {})
    [user: user, phone: to]
  end
end
