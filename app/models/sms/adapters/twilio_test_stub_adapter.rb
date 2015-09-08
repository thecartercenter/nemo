class Sms::Adapters::TwilioTestStubAdapter < Sms::Adapters::TwilioAdapter
  def self.header_signature_name
    'X-Twilio-Stub-Signature'
  end

  def self.can_deliver?
    false
  end

  def deliver(message)
    # DO NOTHING
  end
end
