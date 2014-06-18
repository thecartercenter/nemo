class Sms::Adapters::FrontlineSmsAdapter < Sms::Adapters::Adapter

  def self.recognize_receive_request?(request)
    %w(from text sent frontline) - request.POST.keys == []
  end

  def service_name
    @service_name ||= "FrontlineSms"
  end

  def deliver(message)
    raise NotImplementedError
  end

  def receive(request)
    Sms::Message.create(
      :direction => 'incoming',
      :from => request.POST['from'],
      :body => request.POST['text'],
      # Frontline appears to send times in the gateway computer's timezone, so we should assume
      # that the gateway computer is in the same timezone as the ELMO instance.
      :sent_at => Time.zone.parse(request.POST['sent']),
      :adapter_name => service_name)
  end
end