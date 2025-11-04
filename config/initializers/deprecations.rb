class Rails::Warning
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

Rails::Warning.logger = ActiveSupport::Logger.new(Rails.root.join("log", "warnings_#{Rails.env}.log"))

if Rails.env.test?
  Warning.process do |warning|
    Rails::Warning.log(warning)
    :raise if ENV["RAISE_WARNINGS"]
  end

  if ENV["IGNORE_GEM_WARNINGS"]
    Gem.path.each do |path|
      Warning.ignore(//, path)
    end
  end

  # Ignored warnings
  Warning.ignore(/Warning: no type cast defined for type "uuid"/) # not a deprecation
end
