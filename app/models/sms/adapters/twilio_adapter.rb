require 'twilio-ruby'

class Sms::Adapters::TwilioAdapter < Sms::Adapters::Adapter
  def self.header_signature_name
    'X-Twilio-Signature'
  end

  # checks if this adapter recognizes an incoming http receive request
  def self.recognize_receive_request?(request)
    request.headers.include?(header_signature_name)
  end

  def self.can_deliver?
    true
  end

  def deliver(message)
    prepare_message_for_delivery(message)

    params = { from: message.from, to: message.to, body: message.body }
    Rails.logger.info("Sending Twilio message: #{params}")

    return true if Rails.env.test?

    begin
      client = Twilio::REST::Client.new(config.twilio_account_sid, config.twilio_auth_token)

      send_message_for_each_recipient(message, client)
    rescue Twilio::REST::RequestError
      raise Sms::Error.new("can not send to invalid number")
    end

    true
  end

  def receive(request)
    params = request.request_parameters.merge(request.query_parameters)

    # return the message
    Sms::Incoming.new(
      from: params[:From],
      to: params[:To],
      body: params[:Body],
      sent_at: Time.zone.now, # Twilio doesn't supply this
      adapter_name: service_name)
  end

  def validate(request)
    params = request.request_parameters.merge(request.query_parameters)
    validator = Twilio::Util::RequestValidator.new(config.twilio_auth_token)
    unless Rails.env.test?
      unless validator.validate(request.original_url, params, request.headers['X-Twilio-Signature'])
        raise Sms::Error.new("Could not validate incoming Twilio message from #{params[:From]}")
      end
    end
  end

  # How replies should be sent.
  def reply_style
    :via_response
  end

  def response_body(reply)
    reply.body
  end

  private

  def send_message_for_each_recipient(message, client)
    message.recipient_numbers.each do |number|
      client.messages.create(
        from: config.twilio_phone_number,
        to: number,
        body: message.body)
    end
  end
end
