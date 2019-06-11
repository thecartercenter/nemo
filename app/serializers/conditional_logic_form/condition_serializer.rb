# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Condition for use in condition form.
  class ConditionSerializer < ApplicationSerializer
    attributes :id, :left_qing_id, :op, :value, :option_node_id, :option_set_id,
      :form_id, :conditionable_id, :conditionable_type, :operator_options

    has_many :refable_qings, serializer: TargetFormItemSerializer

    delegate :id, :conditionable_id, :value, to: :object

    def operator_options
      object.applicable_operator_names.map { |n| {name: I18n.t("condition.operators.select.#{n}"), id: n} }
    end

    def option_set_id
      object.left_qing&.option_set_id
    end
  end
end
