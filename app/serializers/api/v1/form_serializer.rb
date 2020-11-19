# frozen_string_literal: true

class API::V1::FormSerializer < ApplicationSerializer
  fields :id, :name, :responses_count
  transform UnderscoreTransformer

  view :show do
    # Workaround: Blueprinter views should inherit transformers but they don't.
    transform UnderscoreTransformer

    field :questions do |object|
      object.api_visible_questions.as_json(only: %i[id code], methods: :name)
    end
  end
end
