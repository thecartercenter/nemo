FactoryGirl.define do
  factory :option_set do
    name "YesNo"
    options {[
      Option.create(:value => 1, :name_eng => "Yes", :mission => get_mission), 
      Option.create(:value => 2, :name_eng => "No", :mission => get_mission)
    ]}
    ordering "value_asc"
    mission get_mission
  end
end