# frozen_string_literal: true

module ResponseFormConditionalLogic
  # Serializes condition group for response web form display logic
  class ConditionGroupSerializer < ApplicationSerializer
    attributes :members, :true_if, :negate, :type, :name

    def members
      object.members.map do |m|
        if m.is_a?(Forms::ConditionGroup)
          ConditionGroupSerializer.new(m)
        else
          ConditionSerializer.new(m)
        end
      end
    end

    def type
      object.model_name.name.demodulize
    end
  end
end
