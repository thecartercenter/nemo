FactoryGirl.define do
  factory :option_set do
    ignore do
      # First level option names.
      option_names %w(Cat Dog)

      multi_level false
    end

    sequence(:name) { |n| "Option Set #{n}" }
    mission { is_standard ? nil : get_mission }
    children_attribs do
      if multi_level
        OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS
      else
        option_names.map{ |n| { 'option_attribs' => { 'name_translations' => {'en' => n} } } }
      end
    end

    level_names do
      if multi_level
        [{'en' => 'Kingdom'}, {'en' => 'Species'}]
      else
        nil
      end
    end

    factory :empty_option_set do
      children_attribs []
    end
  end
end