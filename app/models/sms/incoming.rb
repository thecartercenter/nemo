class Sms::Incoming < Sms::Message
  belongs_to :user

  def recipients
    []
  end

  def recipient_hashes
    [user: "ELMO", phone: to]
  end
end
