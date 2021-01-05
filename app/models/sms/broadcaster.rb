# frozen_string_literal: true

module Sms
  # Sends broadcast SMS messages, analogous to a mailer class for email.
  class Broadcaster
    include ActiveModel::Model

    attr_accessor :mission

    def deliver(broadcast)
      adapter_name = mission_config.default_outgoing_sms_adapter
      raise Sms::Error, I18n.t("sms.no_valid_adapter") if adapter_name.blank?
      body = "[#{mission_config.site_name}] #{broadcast.body}"
      message = Sms::Broadcast.new(broadcast: broadcast, body: body, mission: mission)
      Sms::Adapters::Factory.instance.create(adapter_name, config: mission_config).deliver(message)
    end

    private

    def mission_config
      @mission_config ||= Setting.for_mission(mission)
    end
  end
end
