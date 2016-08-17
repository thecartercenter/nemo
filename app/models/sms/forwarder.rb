class Sms::Forwarder < Sms::MassMessenger
  def self.deliver(broadcast, which_phone, msg)
    # first ensure we have a valid adapter
    ensure_adapter

    # build the sms
    message = Sms::Forward.new(broadcast: broadcast, body: msg, mission: broadcast.mission)

    # deliver
    configatron.outgoing_sms_adapter.deliver(message)
  end
end
