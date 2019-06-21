# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes SkipRules for use in skip rule form.
  class SkipRuleSerializer < ApplicationSerializer
    attributes :id, :skip_if, :destination, :rank, :source_item_id, :dest_item_id
    has_many :conditions, serializer: ConditionSerializer
  end
end
