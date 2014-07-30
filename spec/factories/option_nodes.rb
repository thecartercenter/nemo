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
      children_attribs [
        { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
        { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} } }
      ]
    end

    factory :option_node_with_grandchildren do
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
end
