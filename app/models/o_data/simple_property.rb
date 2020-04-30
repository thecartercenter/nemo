# frozen_string_literal: true

module OData
  class SimpleProperty
    attr_reader :name, :return_type

    # Name is only needed for key_property.
    def initialize(name: "")
      @name = name
      @return_type = :text
    end

    def nullable?
      true
    end
  end
end
