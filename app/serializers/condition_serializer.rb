# == Schema Information
#
# Table name: conditions
#
#  id                 :uuid             not null, primary key
#  conditionable_type :string           not null
#  op                 :string(255)      not null
#  rank               :integer          not null
#  value              :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  conditionable_id   :uuid             not null
#  mission_id         :uuid
#  option_node_id     :uuid
#  ref_qing_id        :uuid             not null
#
# Indexes
#
#  index_conditions_on_conditionable_id                         (conditionable_id)
#  index_conditions_on_conditionable_type_and_conditionable_id  (conditionable_type,conditionable_id)
#  index_conditions_on_mission_id                               (mission_id)
#  index_conditions_on_option_node_id                           (option_node_id)
#  index_conditions_on_ref_qing_id                              (ref_qing_id)
#
# Foreign Keys
#
#  conditions_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  conditions_option_node_id_fkey  (option_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#  conditions_ref_qing_id_fkey     (ref_qing_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#

class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :conditionable_id, :conditionable_type, :ref_qing_id, :form_id,
    :op, :value, :option_node_id
end
