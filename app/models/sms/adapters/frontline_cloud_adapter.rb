# frozen_string_literal: true

class Sms::Adapters::FrontlineCloudAdapter < Sms::Adapters::Adapter
  def self.recognize_receive_request?(request, config:)
    %w[from body sent_at frontlinecloud] - request.params.keys == []
  end

  def self.can_deliver?
    true
  end

  def reply_style
    :via_adapter
  end

  def deliver(message)
    prepare_message_for_delivery(message)
    log_delivery(message)

    # build the request payload
    recipients = message.recipient_numbers.map { |number| {"type" => "mobile", "value" => number} }

    payload = {
      "apiKey" => config.frontlinecloud_api_key,
      "payload" => {
        "message" => message.body,
        "recipients" => recipients
      }
    }
    uri = URI("https://cloud.frontlinesms.com/api/1/webhook")

    send_request(uri, :post, payload)

    # if we get to this point, it worked
    true
  end

  def receive(request)
    params = request.params
    Sms::Incoming.new(
      from: PhoneNormalizer.normalize(params["from"]),
      to: nil, # Frontline doesn't provide this.
      body: params["body"],
      sent_at: convert_time(params["sent_at"]),
      adapter_name: service_name
    )
  end

  def validate(request)
  end

  private

  def convert_time(timestamp)
    timestamp = timestamp.to_i / 1000 # frontlinecloud sends unix timestamp in milliseconds
    Time.zone.at(timestamp)
  end
end
