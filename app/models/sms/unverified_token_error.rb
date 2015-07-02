module Sms
  class UnverifiedTokenError < Error
    def initialize(message=nil)
      message ||= 'Could not verify incoming SMS token'
      super
    end
  end
end
