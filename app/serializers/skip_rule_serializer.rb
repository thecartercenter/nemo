class SkipRuleSerializer < ActiveModel::Serializer
  attributes :id, :skip_if, :destination, :rank, :source_item_id, :dest_item_id
  format_keys :lower_camel
  has_many :conditions, serializer: ConditionViewSerializer
end
