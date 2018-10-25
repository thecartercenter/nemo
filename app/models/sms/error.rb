# frozen_string_literal: true

module Sms
  # Base class, all other SMS errors inherit from this
  class Error < StandardError
  end
end
