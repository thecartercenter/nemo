FactoryGirl.define do
  factory :option_node do
    option
  end

  factory :option_node_with_children, class: OptionNode do
    mission { is_standard ? nil : get_mission }
    option nil
    children_attribs [
      { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
      { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} } }
    ]
  end

  factory :option_node_with_grandchildren, class: OptionNode do
    mission { is_standard ? nil : get_mission }
    option nil
    children_attribs [{
      'option_attribs' => { 'name_translations' => {'en' => 'Animal'} },
      'children_attribs' => [
        { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
        { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} } }
      ]
    }, {
      'option_attribs' => { 'name_translations' => {'en' => 'Plant'} },
      'children_attribs' => [
        { 'option_attribs' => { 'name_translations' => {'en' => 'Tulip'} } },
        { 'option_attribs' => { 'name_translations' => {'en' => 'Oak'} } }
      ]
    }]
  end
end
