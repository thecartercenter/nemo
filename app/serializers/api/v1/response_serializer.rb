# frozen_string_literal: true

class API::V1::ResponseSerializer < ActiveModel::Serializer
  attributes :id, :submitter, :created_at, :updated_at

  has_many :answers, serializer: API::V1::AnswerSerializer

  def submitter
    object.user.name
  end

  def answers
    object.answers.public_access
  end
end
