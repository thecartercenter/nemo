class Sms::Adapters::Factory
  VALID_ADAPTERS = ["IntelliSms", "ISMS", "SMSSYNC"]
  
  def self.name_is_valid?(name)
    VALID_ADAPTERS.include?(name)
  end
  
  # creates an instance of the specified adapter
  def create(name)
    raise ArgumentError.new("Invalid adapter name") unless self.class.name_is_valid?(name)
    Sms::Adapters.const_get("#{name}Adapter").new
  end
end
