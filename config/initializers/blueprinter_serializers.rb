# frozen_string_literal: true

Blueprinter.configure do |config|
  config.default_transformers = [LowerCamelTransformer]
  config.sort_fields_by = :definition
end
