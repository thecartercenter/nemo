class SkipRuleSerializer < ActiveModel::Serializer
  attributes :id, :skip_if, :destination, :rank, :source_item_id, :dest_item_id
  has_many :conditions, serializer: ConditionViewSerializer
end
