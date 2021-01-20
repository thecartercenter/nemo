# frozen_string_literal: true

require "twilio-ruby"

class Sms::Adapters::TwilioAdapter < Sms::Adapters::Adapter
  def self.header_signature_name
    "X-Twilio-Signature"
  end

  # checks if this adapter recognizes an incoming http receive request
  def self.recognize_receive_request?(request, config:)
    request.headers.include?(header_signature_name)
  end

  def self.can_deliver?
    true
  end

  # If dry_run is not specified, it will default to true in test mode,
  # false otherwise. This is needed for some older specs that assume
  # adapters won't actually send messages. This assumption should be
  # deprecated, and newer specs should either mock the client (model
  # specs, see twilio_sms_adapter_spec.rb) or use the ENV stubbing
  # functionality (feature specs) to disable sending.
  def deliver(message, dry_run: nil)
    dry_run = Rails.env.test? if dry_run.nil?

    prepare_message_for_delivery(message)
    log_delivery(message)

    params = {from: message.from, to: message.to, body: message.body}
    Rails.logger.info("Sending Twilio message: #{params}")

    return true if dry_run

    send_message_for_each_recipient(message)

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
      adapter_name: service_name
    )
  end

  def validate(request)
    params = request.request_parameters.merge(request.query_parameters)
    validator = Twilio::Util::RequestValidator.new(config.twilio_auth_token)
    return if Rails.env.test?
    return if validator.validate(request.original_url, params, request.headers["X-Twilio-Signature"])
    raise Sms::Error, "Could not validate incoming Twilio message from #{params[:From]}"
  end

  # How replies should be sent.
  def reply_style
    :via_response
  end

  def response_body(reply)
    reply.body
  end

  private

  # Sends one message per recipient.
  # If the first three sends all fail OR if there are less than 3 recipients and all sends fail,
  # raises a Sms::Adapters::FatalSendError. If some, but not all of the sends fail,
  # raises a Sms::Adapters::PartialSendError.
  # Errors raised will contain the error messages received separated by newlines.
  def send_message_for_each_recipient(message)
    errors = []
    (numbers = message.recipient_numbers).each_with_index do |number, index|
      send_message(number, message.body)
    rescue Twilio::REST::RequestError => e
      errors << e.to_s
      # Check if creating the first 3 messages, or ALL the messages, all failed
      if errors.size == numbers.size || errors.size == 3 && index == 2
        raise Sms::Adapters::FatalSendError, errors.join("\n")
      end
    end
    raise Sms::Adapters::PartialSendError, errors.join("\n") unless errors.empty?
  end

  def client
    @client ||= Twilio::REST::Client.new(config.twilio_account_sid, config.twilio_auth_token)
  end

  def send_message(to, body)
    client.messages.create(from: config.twilio_phone_number, to: to, body: body)
  end
end
