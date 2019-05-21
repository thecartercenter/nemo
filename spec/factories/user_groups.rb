# frozen_string_literal: true

FactoryGirl.define do
  factory :user_group do
    sequence(:name) { |n| "UserGroup #{n}" }
    mission { get_mission }
  end
end
