FactoryGirl.define do
  factory :form do
    name { "Form #{rand(1000000)}" }
    mission { get_mission }
  end
end