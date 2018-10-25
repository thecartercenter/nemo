# frozen_string_literal: true

module Sms
  module Adapters
    # some of the operation succeeded but included some errors
    class PartialSendError < Sms::Error
    end
  end
end
