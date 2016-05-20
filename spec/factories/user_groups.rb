FactoryGirl.define do
  factory :user_group do
    name { Faker::Team.name }
    mission
  end
end
