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
    raise NotImplementedError
  end

  def receive(request)
    params = request.request_parameters.merge(request.query_parameters)

    # create and return the message
    Sms::Incoming.create(
      :from => params[:From],
      :to => params[:To],
      :body => params[:Body],
      :sent_at => Time.zone.now, # Twilio doesn't supply this
      :adapter_name => service_name)
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
