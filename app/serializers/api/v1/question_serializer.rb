class API::V1::QuestionSerializer < ActiveModel::Serializer
  attributes :question, :code, :answer

  def code
    object.question.code
  end

  def question
    object.question.name
  end

  def answer
    object.casted_value
  end
end
