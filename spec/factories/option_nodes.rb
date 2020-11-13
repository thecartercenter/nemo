# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: option_nodes
#
#  id             :uuid             not null, primary key
#  ancestry       :text
#  ancestry_depth :integer          default(0), not null
#  rank           :integer          default(1), not null
#  sequence       :integer          default(0), not null
#  standard_copy  :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  mission_id     :uuid
#  old_id         :integer
#  option_id      :uuid
#  option_set_id  :uuid             not null
#  original_id    :uuid
#
# Indexes
#
#  index_option_nodes_on_ancestry       (ancestry)
#  index_option_nodes_on_mission_id     (mission_id)
#  index_option_nodes_on_option_id      (option_id)
#  index_option_nodes_on_option_set_id  (option_set_id)
#  index_option_nodes_on_original_id    (original_id)
#  index_option_nodes_on_rank           (rank)
#
# Foreign Keys
#
#  option_nodes_mission_id_fkey     (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  option_nodes_option_id_fkey      (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#  option_nodes_option_set_id_fkey  (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :option_node do
    transient do
      option_names { %w[Cat Dog] }
    end

    mission { get_mission }
    option
    option_set

    factory :option_node_with_no_children do
      option { nil }
      children_attribs { [] }
    end

    factory :option_node_with_children do
      option { nil }
      children_attribs do
        option_names.map { |n| {"option_attribs" => {"name_translations" => {"en" => n}}} }
      end
    end

    factory :option_node_with_grandchildren do
      option { nil }
      children_attribs { OptionNodeSupport::MULTILEVEL_ATTRIBS }
    end

    factory :option_node_with_great_grandchildren do
      option { nil }
      children_attribs { OptionNodeSupport::SUPER_MULTILEVEL_ATTRIBS }
    end
  end
end
