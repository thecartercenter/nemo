# Serializes data related to the front-end handling of conditional logic for this item.
class FormItemConditionSerializer < ActiveModel::Serializer
  attributes :display_if

  has_many :display_conditions
end
