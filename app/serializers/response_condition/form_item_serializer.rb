# Serializes data related to the front-end handling of conditional logic for this item.
module ResponseCondition
  class FormItemSerializer < ActiveModel::Serializer
    attributes :id, :group?, :condition_group, :full_dotted_rank
    #TODO: format_keys :lower_camel

    attr_accessor :condition_computer

    def initialize(object, condition_computer:)
      super(object)
      self.condition_computer = condition_computer
    end

    def condition_group
      ResponseCondition::ConditionGroupSerializer.new(self.condition_computer.condition_group_for(object))
    end
  end
end