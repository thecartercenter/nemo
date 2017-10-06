FactoryGirl.define do
  factory :setting do
    timezone "Saskatchewan" # No DST!
    preferred_locales_str "en"
    default_outgoing_sms_adapter "Twilio"
    twilio_account_sid "user"
    twilio_auth_token "pass"
    incoming_sms_token SecureRandom.hex
    incoming_sms_numbers []
  end
end
