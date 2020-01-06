# frozen_string_literal: true

# Class created to be used on testing (specially on load testing).
# It's just a TwilioAdapter that doesn't deliver the sms messages
# This is used to avoid overloading Twilio with a lot of requests when doing
# 1m sms submissions, for example.
class Sms::Adapters::TwilioTestStubAdapter < Sms::Adapters::TwilioAdapter
  def self.header_signature_name
    "X-Twilio-Stub-Signature"
  end

  def self.can_deliver?
    false
  end

  def deliver(message)
    # DO NOTHING
  end

  def validate(request)
  end

  def response_body(reply)
    reply.body
  end
end
