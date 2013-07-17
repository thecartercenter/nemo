FactoryGirl.define do
  factory :response do
    user
    form
    mission { get_mission }
  end
end