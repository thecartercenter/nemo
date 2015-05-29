FactoryGirl.define do
  factory :option do
    sequence(:name_en) { |n| "Option #{n}" }
    mission { get_mission }
  end
end