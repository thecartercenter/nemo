class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :conditionable_id, :conditionable_type, :ref_qing_id, :form_id,
    :op, :value, :option_node_id
end
