FactoryGirl.define do
  factory :option do
    sequence(:name_en) { |n| "Option #{n}" }
    mission { is_standard ? nil : get_mission }
  end
end