class Sms::Broadcaster

  def self.deliver(broadcast, which_phone, msg)
    # first ensure we have a valid adapter
    ensure_adapter

    # build the sms
    message = Sms::Broadcast.new(broadcast: broadcast, body: msg, mission: broadcast.mission)

    # deliver
    configatron.outgoing_sms_adapter.deliver(message)
  end

  # check_balance uses the outgoing adapter to retrieve the SMS balance
  def self.check_balance
    # first ensure we have a valid adapter
    ensure_adapter

    configatron.outgoing_sms_adapter.check_balance
  end

  def self.outgoing_service_name
    # first ensure we have a valid adapter
    ensure_adapter

    configatron.outgoing_sms_adapter.service_name
  end

  private
    # checks for a valid adapter and raises an error it there is none
    def self.ensure_adapter
      raise Sms::Error.new(I18n.t("sms.no_valid_adapter")) unless configatron.to_h[:outgoing_sms_adapter]
    end
end
