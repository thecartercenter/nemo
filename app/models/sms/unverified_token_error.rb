module Sms
  class UnverifiedTokenError < Sms::GenericError
    def initialize(message=nil)
      message ||= 'Could not verify incoming SMS token'
      super
    end
  end
end
