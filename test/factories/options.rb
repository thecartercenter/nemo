FactoryGirl.define do
  factory :option do
    name_en "Yes"
    is_standard false
    mission { is_standard ? nil : get_mission }
  end
end