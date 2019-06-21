# frozen_string_literal: true

module ResponseFormConditionalLogic
  # Serializes data related to the front-end handling of conditional logic for this item.
  class FormItemSerializer < ApplicationSerializer
    attributes :id, :group?, :condition_group, :full_dotted_rank

    attr_accessor :response_condition_group

    def initialize(object, response_condition_group:)
      super(object)
      self.response_condition_group = response_condition_group
    end

    def condition_group
      ConditionGroupSerializer.new(response_condition_group)
    end
  end
end
