class Sms::Broadcaster
  def self.deliver(broadcast, which_phone, msg)
    # first ensure we have a valid adapter
    ensure_adapter

    # build the sms
    message = Sms::Broadcast.new(broadcast: broadcast, body: msg, mission: broadcast.mission)

    # deliver
    configatron.outgoing_sms_adapter.deliver(message)
  end

  private

  # checks for a valid adapter and raises an error it there is none
  def self.ensure_adapter
    return if configatron.to_h[:outgoing_sms_adapter]
    raise Sms::GenericError, I18n.t("sms.no_valid_adapter")
  end
end
