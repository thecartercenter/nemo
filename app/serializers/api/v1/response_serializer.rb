# frozen_string_literal: true

class API::V1::ResponseSerializer < ApplicationSerializer
  transform UnderscoreTransformer

  fields :id

  field :submitter do |object|
    object.user.name
  end

  fields :created_at, :updated_at

  association :answers, blueprint: API::V1::AnswerSerializer, options: {view: :api} do |object|
    object.answers.public_access
  end
end
