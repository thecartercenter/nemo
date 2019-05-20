FactoryGirl.define do
  factory :option_set do
    transient do
      # First level option names. Can also be a symbol which refers to a set in OptionNodeSupport.
      option_names %w[Cat Dog]

      # First level option values. Only works with default or manually specified option names.
      option_values []
    end

    sequence(:name) { |n| "Option Set #{n}" }
    mission { get_mission }

    children_attribs do
      if option_names.is_a?(Symbol)
        "OptionNodeSupport::#{option_names.upcase}_ATTRIBS".constantize
      else
        option_names.each_with_index.map do |n, i|
          {"option_attribs" => {"name_translations" => {"en" => n}, "value" => option_values[i]}}
        end
      end
    end

    level_names do
      case option_names
      when :multilevel then [{"en" => "Kingdom"}, {"en" => "Species"}]
      when :geo_multilevel then [{"en" => "Country"}, {"en" => "City"}]
      when :super_multilevel then [{"en" => "Kingdom"}, {"en" => "Family"}, {"en" => "Species"}]
      end
    end

    factory :empty_option_set do
      children_attribs []
    end

    trait :standard do
      mission { nil }
    end
  end
end
