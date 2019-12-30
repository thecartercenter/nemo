# frozen_string_literal: true

module ActiveSupport #:nodoc:
  class SafeBuffer < String
    def to_param
      to_str
    end
  end
end
