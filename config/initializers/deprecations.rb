class Rails::Warning
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

Rails::Warning.logger = ActiveSupport::Logger.new Rails.root.join("log", "warnings_#{Rails.env}.log")

if Rails.env.test?
  Warning.process do |warning|
    Rails::Warning.log(warning)
    if ENV["RAISE_WARNINGS"]
      :raise
    end
  end

  if ENV["IGNORE_GEM_WARNINGS"]
    Gem.path.each do |path|
      Warning.ignore(//, path)
    end
  end
  
  # Ignored warnings
  Warning.ignore(/Warning: no type cast defined for type "uuid"/) # not a deprecation
end