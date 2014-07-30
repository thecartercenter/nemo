OPTION_NODE_WITH_CHILDREN_ATTRIBS = [
  { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
  { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} } }
]

OPTION_NODE_WITH_GRANDCHILDREN_ATTRIBS = [{
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
