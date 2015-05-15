class Sms::Adapters::TwilioAdapter < Sms::Adapters::Adapter
  # checks if this adapter recognizes an incoming http receive request
  def self.recognize_receive_request?(request)
    request.headers.include?('X-Twilio-Signature')
  end

  def self.can_deliver?
    true
  end

  def deliver(message)
    raise NotImplementedError
  end

  def receive(params)
    raise NotImplementedError
  end

  # Check_balance returns the balance string. Raises error if balance check failed.
  def check_balance
    raise NotImplementedError
  end

  # How replies should be sent.
  def reply_style
    :via_response
  end
end
