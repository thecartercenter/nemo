# frozen_string_literal: true

module OData
  class SimpleEntity
    attr_reader :name, :plural_name, :qualified_name, :key_property, :properties, :navigation_properties

    def initialize(name)
      @name = name
      @plural_name = name
      @qualified_name = name
      @key_property = SimpleProperty.new("Id")
      @properties = {Shortcode: SimpleProperty.new("Shortcode")}
      @navigation_properties = []
    end
  end
end
