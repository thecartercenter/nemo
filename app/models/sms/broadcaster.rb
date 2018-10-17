# frozen_string_literal: true

module Sms
  # Sends broadcast SMS messages, analogous to a mailer class for email.
  class Broadcaster
    def self.deliver(broadcast, which_phone, msg)
      raise Sms::GenericError, I18n.t("sms.no_valid_adapter") unless configatron.to_h[:outgoing_sms_adapter]
      message = Sms::Broadcast.new(broadcast: broadcast, body: msg, mission: broadcast.mission)
      configatron.outgoing_sms_adapter.deliver(message)
    end
  end
end
