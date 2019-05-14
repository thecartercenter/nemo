# frozen_string_literal: true

FactoryGirl.define do
  factory :constraint do
    accept_if { "all_met" }
    rank { 1 }
    mission { get_mission }
    questioning
    rejection_msg { "It's invalid" }
  end
end
