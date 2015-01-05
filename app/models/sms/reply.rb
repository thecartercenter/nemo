class Sms::Reply < Sms::Message
  belongs_to :user
  belongs_to :reply_to, class_name: "Sms::Incoming"

  def recipients
    [to]
  end

  def recipient_hashes
    [user: user, phone: to]
  end
end
