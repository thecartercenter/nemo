# frozen_string_literal: true

# Error encountered while parsing an incoming SMS message
module Sms
  module Parser
    class Error < Sms::Error
      attr_reader :type, :params

      def initialize(type, params = {})
        super(type)
        @type = type
        @params = params
      end

      def to_s
        super + " #{@params.inspect}"
      end
    end
  end
end
