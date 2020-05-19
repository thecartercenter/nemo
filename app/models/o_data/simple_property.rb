# frozen_string_literal: true

module OData
  # Represents a property of an OData entity for our metadata.
  class SimpleProperty
    attr_reader :name, :return_type

    # Note: Name is only needed for key_property.
    # Note: Property types are defined in odata_server's
    # `Property.column_adapter_return_types` static variable.
    def initialize(name: "", return_type: :text)
      @name = name
      @return_type = OData::ActiveRecordSchema::Property.column_adapter_return_types[return_type] || return_type
    end

    def nullable?
      true
    end
  end
end
