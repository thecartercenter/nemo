# frozen_string_literal: true

AttributeNormalizer.configure do |config|
  config.normalizers[:downcase] = lambda do |value, _options|
    value.is_a?(String) ? value.downcase : value
  end
end
