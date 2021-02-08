# frozen_string_literal: true

class OfflineModeMailInterceptor
  def self.delivering_email(message)
    puts ENV["NEMO_OFFLINE_MODE"].inspect
    puts "CHECKING DELIVERIES #{Cnfg.offline_mode?.inspect}"
    message.perform_deliveries = false if Cnfg.offline_mode?
  end
end
ActionMailer::Base.register_interceptor(OfflineModeMailInterceptor)
