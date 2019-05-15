# == Schema Information
#
# Table name: skip_rules
#
#  id             :uuid             not null, primary key
#  destination    :string           not null
#  rank           :integer          not null
#  skip_if        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  dest_item_id   :uuid
#  mission_id     :uuid
#  source_item_id :uuid             not null
#
# Indexes
#
#  index_skip_rules_on_dest_item_id    (dest_item_id)
#  index_skip_rules_on_source_item_id  (source_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (dest_item_id => form_items.id)
#  fk_rails_...  (source_item_id => form_items.id)
#

class SkipRuleSerializer < ActiveModel::Serializer
  attributes :id, :skip_if, :destination, :rank, :source_item_id, :dest_item_id
  format_keys :lower_camel
  has_many :conditions, serializer: ConditionViewSerializer
end
