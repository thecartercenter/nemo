def get_mission
  Mission.first || FactoryGirl.create(:mission)
end

FactoryGirl.define do
  factory :mission do
    name "TheMission"
  end
end