FactoryGirl.define do
  factory :setting do
    timezone "Saskatchewan" # No DST!
    preferred_locales_str "en"
    default_outgoing_sms_adapter "IntelliSms"
    intellisms_username "user"
    intellisms_password "pass"
    incoming_sms_token SecureRandom.hex
    incoming_sms_numbers []
  end
end
