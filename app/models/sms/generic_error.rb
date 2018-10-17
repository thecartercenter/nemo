# frozen_string_literal: true

module Sms
  # base class, all other SMS errors inherit from this
  class GenericError < StandardError
  end
end
