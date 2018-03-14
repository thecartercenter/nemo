# Serializes data related to the front-end handling of conditional logic for this item.
class FormItemDisplayLogicSerializer < ActiveModel::Serializer
  attributes :id, :group?, :condition_group
  #TODO: format_keys :lower_camel

  def condition_group
    DisplayLogicConditionGroupSerializer.new(object.condition_group)
  end
end
