class Sms::Incoming < Sms::Message
  belongs_to :user

  before_save { set_user_by_phone(from) }
end
