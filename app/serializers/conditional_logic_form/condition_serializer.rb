# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Condition for use in condition form.
  class ConditionSerializer < ApplicationSerializer
    fields :id, :left_qing_id, :right_qing_id, :right_side_type, :op, :value, :option_node_id

    field :option_set_id do |object|
      object.left_qing&.option_set_id
    end

    fields :form_id, :conditionable_id, :conditionable_type

    field :operator_options do |object|
      object.applicable_operator_names.map { |n| {name: I18n.t("condition.operators.select.#{n}"), id: n} }
    end
  end
end
