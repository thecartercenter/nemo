class Sms::Incoming < Sms::Message
  # User may be nil if sent from an unrecognized number.
  belongs_to :user

  # Lookup the sender.
  before_create do
    self.user ||= User.by_phone(from)
    return true
  end

  def sender
    user
  end

  def recipient_count
    1
  end

  def recipient_numbers
    [to]
  end

  def recipient_hashes(options = {})
    [user: User::ELMO, phone: to]
  end
end
