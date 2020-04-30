# frozen_string_literal: true

module OData
  class SimpleProperty
    attr_reader :name, :return_type

    # Name is only needed for key_property.
    def initialize(name: "", return_type: :text)
      @name = name
      @return_type = OData::ActiveRecordSchema::Property.column_adapter_return_types[return_type]
    end

    def nullable?
      true
    end
  end
end
