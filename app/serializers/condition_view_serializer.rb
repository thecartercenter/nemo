class ConditionViewSerializer < ActiveModel::Serializer
  attributes :id, :ref_qing_id, :op, :value, :option_node_id, :option_set_id,
    :form_id, :conditionable_id, :operator_options

  has_many :refable_qings, serializer: RefableQuestioningSerializer

  def id
    object.id
  end

  def conditionable_id
    object.conditionable_id
  end

  def operator_options
    object.applicable_operator_names.map { |n| {name: I18n.t("condition.operators.#{n}"), id: n} }
  end

  def value
    object.value
  end

  def option_set_id
    object.ref_qing.try(:option_set_id)
  end
end
