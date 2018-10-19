# frozen_string_literal: true

module Sms
  module Adapters
    # error indicating that the entire operation was not able to succeed
    class FatalSendError < Sms::Error
    end
  end
end
