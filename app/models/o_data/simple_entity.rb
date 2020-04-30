# frozen_string_literal: true

module OData
  class SimpleEntity
    attr_reader :name, :plural_name, :qualified_name, :key_property, :properties, :navigation_properties,
      :extra_tags

    def initialize(name, key_name: "ID", properties: {}, extra_tags: {})
      @name = name
      @plural_name = name
      @qualified_name = name
      @key_property = SimpleProperty.new(name: key_name)
      @properties = properties
      @navigation_properties = []
      @extra_tags = extra_tags
    end
  end
end
