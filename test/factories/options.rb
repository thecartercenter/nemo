FactoryGirl.define do
  factory :option do
    name_en "Yes"
    mission { is_standard ? nil : get_mission }
  end
end