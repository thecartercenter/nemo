# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: option_sets
#
#  id                   :uuid             not null, primary key
#  allow_coordinates    :boolean          default(FALSE), not null
#  geographic           :boolean          default(FALSE), not null
#  level_names          :jsonb
#  name                 :string(255)      not null
#  sms_guide_formatting :string(255)      default("auto"), not null
#  standard_copy        :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mission_id           :uuid
#  original_id          :uuid
#  root_node_id         :uuid
#
# Indexes
#
#  index_option_sets_on_geographic           (geographic)
#  index_option_sets_on_mission_id           (mission_id)
#  index_option_sets_on_name_and_mission_id  (name,mission_id) UNIQUE
#  index_option_sets_on_original_id          (original_id)
#  index_option_sets_on_root_node_id         (root_node_id) UNIQUE
#
# Foreign Keys
#
#  option_sets_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  option_sets_option_node_id_fkey  (root_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :option_set do
    transient do
      # First level option names. Can also be a symbol which refers to a set in OptionNodeSupport.
      option_names { %w[Cat Dog] }

      # First level option values. Only works with default or manually specified option names.
      option_values { [] }
    end

    sequence(:name) { |n| "Option Set #{n}" }
    mission { get_mission }

    children_attribs do
      if option_names.is_a?(Symbol)
        "OptionNodeSupport::#{option_names.upcase}_ATTRIBS".constantize
      else
        option_names.each_with_index.map do |n, i|
          {"option_attribs" => {"name_translations" => {"en" => n}, "value" => option_values[i]}}
        end
      end
    end

    level_names do
      case option_names
      when :multilevel then [{"en" => "Kingdom"}, {"en" => "Species"}]
      when :geo_multilevel then [{"en" => "Country"}, {"en" => "City"}]
      when :super_multilevel then [{"en" => "Kingdom"}, {"en" => "Family"}, {"en" => "Species"}]
      end
    end

    factory :empty_option_set do
      children_attribs { [] }
    end

    trait :standard do
      mission { nil }
    end
  end
end
