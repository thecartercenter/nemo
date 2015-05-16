require 'twilio-ruby'

class Sms::Adapters::TwilioAdapter < Sms::Adapters::Adapter
  # checks if this adapter recognizes an incoming http receive request
  def self.recognize_receive_request?(request)
    request.headers.include?('X-Twilio-Signature')
  end

  def self.can_deliver?
    true
  end

  def deliver(message)
    prepare_message_for_delivery(message)

    client = Twilio::REST::Client.new configatron.twilio_account_sid, configatron.twilio_auth_token

    params = { from: message.from, to: message.to, body: message.body }
    Rails.logger.info("Sending Twilio message: #{params}")

    return true if Rails.env.test?

    begin
      client.messages.create(
        from: configatron.incoming_sms_number,
        to: message.recipient_numbers.join(','),
        body: message.body)
    rescue Twilio::REST::RequestError => e
      raise Sms::Error.new(e)
    end

    return true
  end

  def receive(request)
    params = request.request_parameters.merge(request.query_parameters)

    validator = Twilio::Util::RequestValidator.new configatron.twilio_auth_token
    unless validator.validate(request.original_url, params, request.headers['X-Twilio-Signature'])
      raise Sms::Error.new("Could not validate incoming Twilio message from #{params[:From]}")
    end

    # create and return the message
    Sms::Incoming.create(
      from: params[:From],
      to: params[:To],
      body: params[:Body],
      sent_at: Time.zone.now, # Twilio doesn't supply this
      adapter_name: service_name)
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
