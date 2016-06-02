FactoryGirl.define do
  factory :user_group do
    name { Faker::Team.name }
    mission { get_mission }
  end
end
