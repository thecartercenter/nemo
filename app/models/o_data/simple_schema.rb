# frozen_string_literal: true

module OData
  # A schema for the odata_server engine that's used in place of the default
  # when generating metadata. It's much simpler than the default and also
  # able to perform NEMO-specific logic.
  class SimpleSchema
    attr_accessor :namespace, :entity_types

    def initialize(distinct_forms)
      self.namespace = OData::NAMESPACE
      self.entity_types = SimpleEntities.new(distinct_forms)
    end
  end
end
