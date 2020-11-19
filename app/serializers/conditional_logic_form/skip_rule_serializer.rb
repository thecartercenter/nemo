# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes SkipRules for use in skip rule form.
  class SkipRuleSerializer < ApplicationSerializer
    fields :id, :skip_if, :destination, :rank, :source_item_id, :dest_item_id
    association :conditions, blueprint: ConditionSerializer
  end
end
