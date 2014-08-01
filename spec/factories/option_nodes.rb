FactoryGirl.define do
  factory :option_node do
    mission { is_standard ? nil : get_mission }
    option

    factory :option_node_with_no_children do
      option nil
      children_attribs []
    end

    factory :option_node_with_children do
      option nil
      children_attribs { OptionNodeSupport::WITH_CHILDREN_ATTRIBS }
    end

    factory :option_node_with_grandchildren do
      option nil
      children_attribs { OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS }
    end
  end
end
