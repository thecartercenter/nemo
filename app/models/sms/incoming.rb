class Sms::Incoming < Sms::Message
  # Lookup the sender.
  before_create do
    self.user ||= User.by_phone(from)
    true
  end

  def sender
    user
  end

  def recipient_count
    1
  end

  def recipient_numbers
    [to] # `to` may be nil
  end

  # Returns a set of hashes of form {user: x, phone: y} for recipients.
  def recipient_hashes(options = {})
    [user: User::SITE, phone: to]
  end
end
