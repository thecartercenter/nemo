class Rails::Debug
  attr_accessor :logger

  class << self
    attr_reader :logger
  end

  class << self
    attr_writer :logger
  end

  def self.log(message)
    @logger.debug(message)
  end
end

Rails::Debug.logger = ActiveSupport::Logger.new(Rails.root.join("log", "debug_#{Rails.env}.log"))
