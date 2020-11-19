# frozen_string_literal: true

module ResponseFormConditionalLogic
  # Serializes condition group for response web form display logic
  class ConditionGroupSerializer < ApplicationSerializer
    field :members do |object|
      object.members.map do |m|
        # Note: Rendering like this is hacky and won't apply transformers automatically
        # if we were to use them in this serializer in the future. Needs thought.
        if m.is_a?(Forms::ConditionGroup)
          ConditionGroupSerializer.render_as_json(m)
        else
          ConditionSerializer.render_as_json(m)
        end
      end
    end

    fields :true_if, :negate

    field :type do |object|
      object.model_name.name.demodulize
    end

    field :name
  end
end
