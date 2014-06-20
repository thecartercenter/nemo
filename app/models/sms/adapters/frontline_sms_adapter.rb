class Sms::Adapters::FrontlineSmsAdapter < Sms::Adapters::Adapter

  def self.recognize_receive_request?(params)
    %w(from text sent frontline) - params.keys == []
  end

  def self.can_deliver?
    false
  end

  def service_name
    @service_name ||= "FrontlineSms"
  end

  def reply_style
    :via_response
  end

  def deliver(message)
    raise NotImplementedError
  end

  def receive(params)
    Sms::Message.create(
      :direction => 'incoming',
      :from => params['from'],
      :body => params['text'],
      # Frontline appears to send times in the gateway computer's timezone, so we should assume
      # that the gateway computer is in the same timezone as the ELMO instance.
      :sent_at => Time.zone.parse(params['sent']),
      :adapter_name => service_name)
  end
end