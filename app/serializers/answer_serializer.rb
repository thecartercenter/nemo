class AnswerSerializer < ActiveModel::Serializer
  attributes :answer_id, :answer_value

  def answer_id
    object.id
  end

  def answer_value
    object.casted_value
  end

end
