# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :option_level do
    rank { 1 }
    name_en { "Level #{rank}" }
    mission { get_mission }

    # pass the mission along to the association
    option_set { build(:option_set, mission: mission) }
  end
end
