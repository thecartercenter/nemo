# frozen_string_literal: true

# rubocop:disable Layout/LineLength
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
#  left_qing_id       :uuid             not null
#  mission_id         :uuid
#  option_node_id     :uuid
#  right_qing_id      :uuid
#
# Indexes
#
#  index_conditions_on_conditionable_id                         (conditionable_id)
#  index_conditions_on_conditionable_type_and_conditionable_id  (conditionable_type,conditionable_id)
#  index_conditions_on_left_qing_id                             (left_qing_id)
#  index_conditions_on_mission_id                               (mission_id)
#  index_conditions_on_option_node_id                           (option_node_id)
#
# Foreign Keys
#
#  conditions_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  conditions_option_node_id_fkey  (option_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...                    (left_qing_id => form_items.id)
#  fk_rails_...                    (right_qing_id => form_items.id)
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :condition do
    op { "eq" }
    left_qing { build(:questioning) }
    value { left_qing.present? && !left_qing.has_options? ? "1" : nil }
    option_node { left_qing&.has_options? ? left_qing.option_set.c[0] : nil }
    mission { get_mission }
  end
end
