# frozen_string_literal: true

class OfflineModeMailInterceptor
  def self.delivering_email(message)
    message.perform_deliveries = false if Cnfg.offline_mode?
  end
end
ActionMailer::Base.register_interceptor(OfflineModeMailInterceptor)
