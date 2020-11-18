# frozen_string_literal: true

module ResponseFormConditionalLogic
  # Serializes data related to the front-end handling of conditional logic for this item.
  class FormItemSerializer < ApplicationSerializer
    fields :id, :group?

    association :condition_group, blueprint: ConditionGroupSerializer do |_object, options|
      options[:response_condition_group]
    end

    field :full_dotted_rank
  end
end
