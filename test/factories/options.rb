FactoryGirl.define do
  factory :option do
    name_en "Yes"
    mission { get_mission }
  end
end