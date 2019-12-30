# frozen_string_literal: true

# Disable root for all serializers
ActiveModel::Serializer.root = false
ActiveModel::ArraySerializer.root = false

ActiveModel::Serializer.setup do |config|
  config.key_format = :lower_camel
end
