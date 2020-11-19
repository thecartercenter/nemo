# frozen_string_literal: true

class API::V1::AnswerSerializer < ApplicationSerializer
  transform UnderscoreTransformer

  fields :id

  field :code do |object|
    object.question.code
  end

  field :question do |object|
    object.question.name
  end

  field :casted_value, name: :value

  view :api do
    # Workaround: Blueprinter views should inherit transformers but they don't.
    transform UnderscoreTransformer

    exclude :code
    exclude :question
  end
end
