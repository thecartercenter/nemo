# Serializes data related to the front-end handling of conditional logic for this item.
class FormItemDisplayLogicSerializer < ActiveModel::Serializer
  attributes :display_if, :id, :group?, :display_conditions

  def display_conditions
    DisplayLogicConditionGroupSerializer.new(object.condition_group)
  end
end
