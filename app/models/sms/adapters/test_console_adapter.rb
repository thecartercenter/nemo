# frozen_string_literal: true

# A dummy adapter used only for the SMS test console.
class Sms::Adapters::TestConsoleAdapter < Sms::Adapters::Adapter
  def self.can_deliver?
    true
  end

  def deliver(message)
    # Don't have to do much here as we're not really sending this message, just pretending!
    prepare_message_for_delivery(message)
    log_delivery(message)
    true
  end

  # Not implemented because the SMS console creates messages directly. Could refactor this later.
  def receive(_request)
    raise NotImplementedError
  end

  def reply_style
    :via_adapter
  end
end
