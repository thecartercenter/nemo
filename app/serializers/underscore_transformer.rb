# frozen_string_literal: true

class UnderscoreTransformer < Blueprinter::Transformer
  def transform(hash, _object, _options)
    hash.transform_keys! { |key| key.to_s.underscore.to_sym }
  end
end
