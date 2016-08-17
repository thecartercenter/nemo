class Sms::Forwarder < Sms::MassMessenger
  def self.deliver(broadcast, response, message)
    # first ensure we have a valid adapter
    ensure_adapter

    message = strip_auth_code(message, response.form)
    
    # build the sms
    message = Sms::Forward.new(broadcast: broadcast, body: message, mission: broadcast.mission)

    # deliver
    configatron.outgoing_sms_adapter.deliver(message)
  end

  private

  def self.strip_auth_code(message, form)
    split_message = message.split(" ")
    split_message.shift if form.authenticate_sms?
    joined_message = split_message.join(" ")
  end
end
