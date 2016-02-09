AttributeNormalizer.configure do |config|
  config.normalizers[:downcase] = lambda do |value, options|
    value.is_a?(String) ? value.downcase : value
  end
end
