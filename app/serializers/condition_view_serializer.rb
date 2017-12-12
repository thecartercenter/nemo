class ConditionViewSerializer < ActiveModel::Serializer
  attributes :id, :ref_qing_id, :op, :value, :option_node, :form_id, :questioning_id, :operator_options

  has_many :refable_qings, serializer: RefableQuestioningSerializer

  def id
    object.id
  end

  def questioning_id
    object.questioning_id
  end

  def operator_options
    object.applicable_operator_names.map { |n| {name: I18n.t("condition.operators.#{n}"), id: n} }
  end

  def value
    object.value
  end

  def option_node
    if object.ref_qing.present? && object.ref_qing_has_options?
      { node_id: object.option_node.try(:id), set_id: object.ref_qing.try(:option_set_id) }
    else
      nil
    end
  end
end
