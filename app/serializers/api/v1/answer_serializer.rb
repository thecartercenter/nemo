# frozen_string_literal: true

class API::V1::AnswerSerializer < ActiveModel::Serializer
  attributes :id, :code, :question, :value
  format_keys :underscore

  def filter(keys)
    keys -= (scope.params[:controller] == "api/v1/answers" ? %i[code question] : [])
  end

  def code
    object.question.code
  end

  def question
    object.question.name
  end

  def value
    object.casted_value
  end
end
