# frozen_string_literal: true

module OData
  class SimpleSchema
    attr_reader :namespace, :entity_types

    def initialize
      @namespace = "NEMO"
      @entity_types = SimpleEntities.new
    end
  end
end
