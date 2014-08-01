FactoryGirl.define do
  factory :option_set do
    ignore do
      # First level option names.
      option_names %w(Cat Dog)
    end

    sequence(:name) { |n| "Option Set #{n}" }
    mission { is_standard ? nil : get_mission }
    children_attribs do
      option_names.map{ |n| { 'option_attribs' => { 'name_translations' => {'en' => n} } } }
    end

    factory :empty_option_set do
      children_attribs []
    end

    factory :multilevel_option_set do
      children_attribs { OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS }
      level_names [{'en' => 'Kingdom'}, {'en' => 'Species'}]
    end
  end
end