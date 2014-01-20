FactoryGirl.define do
  factory :option_set do
    ignore do
      option_names %w(Yes No)
      option_names_with_ranks nil
    end

    mission { is_standard ? nil : get_mission }

    name do
      option_names ? option_names.join : "AnOptionSet"
    end

    optionings do
      if option_names_with_ranks
        # make the optioning objects according to the rank specified
        option_names_with_ranks.each_pair.map do |name, rank|
          Optioning.new(:rank => rank, :option => Option.new(:name => name, :mission => mission), :mission => mission)
        end
      else
        # make the optioning objects, respecting the order they came in
        option_names.each_with_index.map do |name, i|
          Optioning.new(:rank => i + 1, :option => Option.new(:name => name, :mission => mission), :mission => mission)
        end
      end
    end
  end
end