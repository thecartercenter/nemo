# frozen_string_literal: true

module OData
  # Represents a property of an OData entity for our metadata.
  class SimpleProperty
    attr_accessor :name, :return_type

    # Note: Name is only needed for key_property.
    # Note: Property types are defined in odata_server's
    # `Property.column_adapter_return_types` static variable.
    def initialize(name: "", return_type: :text)
      self.name = name
      self.return_type = parse_return_type(return_type)
    end

    def nullable?
      true
    end

    private

    # Parses e.g. `[:id]` => `"Collection(Edm.Guid)"`
    def parse_return_type(return_type)
      return_types_map = OData::ActiveRecordSchema::Property.column_adapter_return_types
      if return_type.is_a?(Array)
        return_array = true
        return_type = return_type[0]
      end
      return_type = return_types_map[return_type] || return_type
      return_array ? "Collection(#{return_type})" : return_type
    end
  end
end
