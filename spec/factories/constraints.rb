# frozen_string_literal: true

FactoryGirl.define do
  factory :constraint do
    transient do
      no_conditions { false }
    end

    accept_if { "all_met" }
    rank { 1 }
    mission { get_mission }
    questioning
    rejection_msg { "It's invalid" }

    after(:build) do |constraint, evaluator|
      unless evaluator.no_conditions
        constraint.conditions << build(:condition, conditionable: constraint,
                                                   ref_qing: constraint.questioning)
      end
    end
  end
end
