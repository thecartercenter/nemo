class Sms::Incoming < Sms::Message
  belongs_to :user

  def sender
    user
  end

  def recipients
    []
  end

  def recipient_hashes
    [user: User::ELMO, phone: to]
  end
end
