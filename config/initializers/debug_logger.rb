class Rails::Debug
  attr_accessor :logger

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.log(message)
    @logger.debug(message)
  end
end

Rails::Debug.logger = ActiveSupport::Logger.new Rails.root.join("log", "debug_#{Rails.env}.log")
