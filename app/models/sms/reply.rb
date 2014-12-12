class Sms::Reply < Sms::Message
  belongs_to :user
  belongs_to :reply_to, class_name: "Sms::Incoming"

  before_save { set_user_by_phone(to) }
end
