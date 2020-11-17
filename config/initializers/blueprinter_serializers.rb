# frozen_string_literal: true

Blueprinter.configure do |config|
  config.default_transformers = [LowerCamelTransformer]
end
