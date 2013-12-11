class Sms::Adapters::Factory
  VALID_ADAPTERS = ["IntelliSms", "Isms"]

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
    Sms::Adapters.const_get("#{name}Adapter").new
  end
end
