class ConditionViewSerializer < ActiveModel::Serializer
  #attributes :id, :questioning_id, :refable_qing_options, :ref_qing_id, :form_id, :operator_options, :op, :value_options, :value, :option_node_id
  attributes :id, :ref_qing_id, :op, :value, :form_id, :questioning_id, :refable_qing_options, :operator_options, :value_options

  def id
    object.id
  end
  
  def form_id
    object.form.id
  end

  def questioning_id
    object.questioning_id
  end

  def refable_qing_options
    object.refable_qings.map{ |q| {code: q.question.code, rank: q.full_dotted_rank, id: q.id} }
  end

  def operator_options
    object.applicable_operator_names.map { |n| {name: I18n.t(n, scope: [:condition, :operators]), id: n} }
  end

  def value_options
    nil
  end
end
