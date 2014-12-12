class Sms::Reply < Sms::Message
  belongs_to :user
  belongs_to :reply_to, class_name: "Sms::Incoming"
end
