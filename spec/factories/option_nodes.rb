FactoryGirl.define do
  factory :option_node do
    transient do
      option_names %w(Cat Dog)
    end

    mission { get_mission }
    option
    option_set

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
      children_attribs { OptionNodeSupport::MULTILEVEL_ATTRIBS }
    end

    factory :option_node_with_great_grandchildren do
      option nil
      children_attribs { OptionNodeSupport::SUPER_MULTILEVEL_ATTRIBS }
    end
  end
end
