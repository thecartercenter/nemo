# frozen_string_literal: true

class Sms::Adapters::Factory
  include Singleton

  VALID_ADAPTERS = %w[Generic FrontlineSms FrontlineCloud Twilio TwilioTestStub TestConsole].freeze

  def self.name_is_valid?(name)
    VALID_ADAPTERS.include?(name)
  end

  # returns an array of known adapter classes
  def self.products(can_deliver: false)
    VALID_ADAPTERS.map { |n| "Sms::Adapters::#{n}Adapter".constantize }.tap do |adapters|
      adapters.select!(&:can_deliver?) if can_deliver
    end
  end

  # creates an instance of the specified adapter
  def create(name_or_class, config:)
    return nil if name_or_class.nil?
    if name_or_class.is_a?(String)
      unless self.class.name_is_valid?(name_or_class)
        raise ArgumentError, "invalid adapter name '#{name_or_class}'"
      end
      klass = Sms::Adapters.const_get("#{name_or_class}Adapter")
    else
      klass = name_or_class
    end
    klass.new(config: config)
  end

  # Creates and returns an adapter that knows how to handle the given HTTP request params.
  # Returns nil if no adapter classes recognized the request.
  def create_for_request(request, config:)
    klass = self.class.products.detect { |a| a.recognize_receive_request?(request, config: config) }
    return nil if klass.nil?
    create(klass, config: config)
  end
end
