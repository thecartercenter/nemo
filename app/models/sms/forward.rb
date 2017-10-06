class Sms::Forward < Sms::Broadcast
  belongs_to :reply_to, class_name: "Sms::Incoming"
end
