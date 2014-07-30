FactoryGirl.define do
  factory :option_set do
    sequence(:name) { |n| "Option Set #{n}" }
    mission { is_standard ? nil : get_mission }
    children_attribs { OPTION_NODE_WITH_CHILDREN_ATTRIBS }

    factory :empty_option_set do
      children_attribs []
    end

    factory :multilevel_option_set do
      children_attribs { OPTION_NODE_WITH_GRANDCHILDREN_ATTRIBS }
      level_names [{'en' => 'Kingdom'}, {'en' => 'Species'}]
    end
  end
end