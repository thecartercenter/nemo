# Serializes condition group for response web form display logic
class DisplayLogicConditionGroupSerializer < ActiveModel::Serializer
  attributes :members, :true_if, :negate, :type

  def members
    object.members.map do |m|
      if m.is_a? Forms::ConditionGroup
        DisplayLogicConditionGroupSerializer.new(m)
      else
        m
      end
    end
  end

  def type
    object.model_name.name.demodulize
  end
end
