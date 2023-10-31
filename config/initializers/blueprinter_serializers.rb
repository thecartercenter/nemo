# frozen_string_literal: true

Blueprinter.configure do |config|
  # Wrapper to autoload classes and modules needed at boot time.
  Rails.application.reloader.to_prepare do
    config.default_transformers = [LowerCamelTransformer]
    config.sort_fields_by = :definition
  end
end
