# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: constraints
#
#  id                         :uuid             not null, primary key
#  accept_if                  :string(16)       default("all_met"), not null
#  rank                       :integer          not null
#  rejection_msg_translations :jsonb
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  mission_id                 :uuid
#  source_item_id             :uuid             not null
#
# Indexes
#
#  index_constraints_on_mission_id               (mission_id)
#  index_constraints_on_source_item_id           (source_item_id)
#  index_constraints_on_source_item_id_and_rank  (source_item_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#  fk_rails_...  (source_item_id => form_items.id)
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :constraint do
    transient do
      no_conditions { false }
    end

    accept_if { "all_met" }
    rank { 1 }
    mission { get_mission }
    association :source_item, factory: :questioning
    rejection_msg { "It's invalid" }

    after(:build) do |constraint, evaluator|
      if !evaluator.no_conditions && constraint.conditions.none?
        constraint.conditions << build(:condition, conditionable: constraint,
                                                   left_qing: constraint.source_item)
      end
    end
  end
end
