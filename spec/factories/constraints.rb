# frozen_string_literal: true

FactoryGirl.define do
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
                                                   ref_qing: constraint.source_item)
      end
    end
  end
end
