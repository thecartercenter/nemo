class Sms::Adapters::Factory
  VALID_ADAPTERS = %w(IntelliSms FrontlineSms)

  def self.name_is_valid?(name)
    VALID_ADAPTERS.include?(name)
  end

  # returns an array of known adapter classes
  def self.products
    VALID_ADAPTERS.map{|n| adapter = "Sms::Adapters::#{n}Adapter".constantize}
  end

  # creates an instance of the specified adapter
  def create(name)
    raise ArgumentError.new("invalid adapter name") unless self.class.name_is_valid?(name)
    klass = Sms::Adapters.const_get("#{name}Adapter")
    klass.new
  end

  # Creates and returns an adapter that knows how to handle the given HTTP request.
  # Returns nil if no adapter classes recognized the request.
  def create_for_request(request)
    klass = Sms::Adapters::Factory.products.detect{|a| a.recognize_receive_request?(request)}
    return nil if klass.nil?
    klass.new
  end
end
