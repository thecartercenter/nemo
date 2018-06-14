# frozen_string_literal: true

module Sms
  module Parser
    # Error encountered while parsing an incoming SMS message
    class Error < Sms::Error
      attr_reader :type, :params

      def initialize(type, params = {})
        super(type)
        @type = type
        @params = params
      end

      def to_s
        super + " #{params.inspect}"
      end
    end
  end
end
