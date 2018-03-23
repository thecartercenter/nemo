# Serializes data related to the front-end handling of conditional logic for this item.
module ResponseCondition
  class FormItemSerializer < ActiveModel::Serializer
    attributes :id, :group?, :condition_group, :full_dotted_rank
    #TODO: format_keys :lower_camel

    attr_accessor :response_condition_group

    def initialize(object, response_condition_group:)
      super(object)
      self.response_condition_group = response_condition_group
    end

    def condition_group
      ResponseCondition::ConditionGroupSerializer.new(self.response_condition_group)
    end
  end
end
