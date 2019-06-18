# frozen_string_literal: true

class ConditionViewSerializer < ActiveModel::Serializer
  attributes :id, :left_qing_id, :op, :value, :option_node_id, :option_set_id,
    :form_id, :conditionable_id, :conditionable_type, :operator_options
  format_keys :lower_camel

  has_many :refable_qings, serializer: TargetFormItemSerializer

  delegate :id, to: :object

  delegate :conditionable_id, to: :object

  def operator_options
    object.applicable_operator_names.map { |n| {name: I18n.t("condition.operators.select.#{n}"), id: n} }
  end

  delegate :value, to: :object

  def option_set_id
    object.left_qing.try(:option_set_id)
  end
end
