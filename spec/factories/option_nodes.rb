FactoryGirl.define do
  factory :option_node do
    ignore do
      option_names %w(Cat Dog)
    end

    mission { is_standard ? nil : get_mission }
    option

    factory :option_node_with_no_children do
      option nil
      children_attribs []
    end

    factory :option_node_with_children do
      option nil
      children_attribs do
        option_names.map{ |n| { 'option_attribs' => { 'name_translations' => {'en' => n} } } }
      end
    end

    factory :option_node_with_grandchildren do
      option nil
      children_attribs { OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS }
    end
  end
end
