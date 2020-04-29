# frozen_string_literal: true

module OData
  class SimpleSchema
    attr_reader :namespace, :entity_types

    def initialize(distinct_forms)
      @namespace = "NEMO"
      @entity_types = SimpleEntities.new(distinct_forms)
    end
  end
end
