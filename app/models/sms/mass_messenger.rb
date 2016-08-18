class Sms::MassMessenger
  def self.deliver
    raise NotImplementedError
  end

  # Check_balance uses the outgoing adapter to retrieve the SMS balance
  # Currently, the only SMS service that supports balance checks via the API is IntelliSMS, and we are
  # moving away from them, so this feature should probably be removed.
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
