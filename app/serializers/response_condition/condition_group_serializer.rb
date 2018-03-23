# frozen_string_literal: true

# Serializes condition group for response web form display logic
module ResponseCondition
  class ConditionGroupSerializer < ActiveModel::Serializer
    attributes :members, :true_if, :negate, :type, :name
    #TODO: format_keys :lower_camel

    def members
      object.members.map do |m|
        if m.is_a? Forms::ConditionGroup
          ResponseCondition::ConditionGroupSerializer.new(m)
        else
          m
        end
      end
    end

    def type
      object.model_name.name.demodulize
    end
  end
end