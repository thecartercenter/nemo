# frozen_string_literal: true

module OData
  # Represents a single OData entity for our metadata.
  # This can be a top-level type (e.g. User) or a sub-type (e.g. a repeat group).
  class SimpleEntity
    attr_accessor :name, :plural_name, :qualified_name, :key_property, :properties,
      :navigation_properties, :extra_tags

    def initialize(name, key_name: nil, property_types: {}, extra_tags: {})
      self.name = name
      self.plural_name = name
      # TODO: Fix `warning: toplevel constant NAMESPACE referenced by ODataController::NAMESPACE`
      self.qualified_name = "#{ODataController::NAMESPACE}.#{name}"
      self.key_property = key_name ? SimpleProperty.new(name: key_name) : nil
      self.properties = property_types.transform_values do |type|
        SimpleProperty.new(return_type: type)
      end
      self.navigation_properties = []
      self.extra_tags = extra_tags
    end
  end
end
