# frozen_string_literal: true

module Sms
  class UnverifiedTokenError < Sms::Error
    def initialize(message = nil)
      message ||= "Could not verify incoming SMS token"
      super
    end
  end
end
