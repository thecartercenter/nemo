FactoryGirl.define do
  factory :option_set do
    transient do
      # First level option names.
      option_names %w(Cat Dog)

      geo false
      multi_level false
      super_multi_level false
    end

    sequence(:name) { |n| "Option Set #{n}" }
    mission { is_standard ? nil : get_mission }
    children_attribs do
      if multi_level
        if geo
          OptionNodeSupport::GEO_WITH_GRANDCHILDREN_ATTRIBS
        else
          OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS
        end
      elsif super_multi_level
        OptionNodeSupport::WITH_GREAT_GRANDCHILDREN_ATTRIBS
      else
        option_names.map{ |n| { 'option_attribs' => { 'name_translations' => {'en' => n} } } }
      end
    end

    level_names do
      if multi_level
        if geo
          [{'en' => 'Country'}, {'en' => 'City'}]
        else
          [{'en' => 'Kingdom'}, {'en' => 'Species'}]
        end
      elsif super_multi_level
        [{'en' => 'Kingdom'}, {'en' => 'Family'}, {'en' => 'Species'}]
      else
        nil
      end
    end

    factory :empty_option_set do
      children_attribs []
    end
  end
end