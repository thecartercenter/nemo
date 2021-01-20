# frozen_string_literal: true

class Sms::Adapters::FrontlineSmsAdapter < Sms::Adapters::Adapter
  def self.recognize_receive_request?(request, config:)
    %w[from text frontline] - request.params.keys == []
  end

  def self.can_deliver?
    false
  end

  def reply_style
    :via_response
  end

  def deliver(_message)
    raise NotImplementedError
  end

  def receive(request)
    params = request.params
    Sms::Incoming.new(
      from: params["from"],
      to: nil, # Frontline doesn't provide this.
      body: params["text"],
      sent_at: Time.zone.now, # Frontline doesn't supply this
      adapter_name: service_name
    )
  end

  def validate(request)
  end

  def response_body(reply)
    reply.body
  end
end
