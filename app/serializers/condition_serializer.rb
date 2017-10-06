class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :questioning_id, :ref_qing_id, :form_id, :op, :value, :option_node_id
end
