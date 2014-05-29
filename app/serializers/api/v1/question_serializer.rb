class API::V1::QuestionSerializer < ActiveModel::Serializer
  attributes :question, :answer

  def question
    object.question.name
  end

  def answer
    object.casted_value
  end
end
