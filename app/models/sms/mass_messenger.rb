class Sms::MassMessenger
  def self.deliver
    raise NotImplementedError
  end

  def self.outgoing_service_name
    # first ensure we have a valid adapter
    ensure_adapter

    configatron.outgoing_sms_adapter.service_name
  end

  private

  # checks for a valid adapter and raises an error it there is none
  def self.ensure_adapter
    unless configatron.to_h[:outgoing_sms_adapter]
      raise Sms::Errors::Error, I18n.t("sms.no_valid_adapter")
    end
  end
end
