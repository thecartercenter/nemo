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

  factory :multilevel_option_set, :class => 'OptionSet' do
    ignore do
      level_names ['kingdom', 'species']

      # must give two levels of option names
      option_names [['animal', ['cat', 'dog']], ['plant', ['pine', 'tulip']]]
    end

    mission { is_standard ? nil : get_mission }

    name 'multilevel'

    multi_level true

    after(:build) do |os, evaluator|
      # build option levels
      evaluator.level_names.each_with_index do |l, i|
        os.option_levels.build(:name => l, :rank => i, :option_set => os, :mission => evaluator.mission)
      end

      # build two levels of optionings
      evaluator.option_names.each_with_index do |names, i|
        # first level
        oing = os.optionings.build(:option => Option.new(:name => names[0], :mission => evaluator.mission), :rank => i,
          :option_level => evaluator.option_levels[0], :mission => evaluator.mission, :option_set => os)

        # second level
        names[1].each_with_index.map do |name2, i2|
          oing.optionings.build(:option => Option.new(:name => name2, :mission => evaluator.mission), :rank => i2,
            :option_level => evaluator.option_levels[1], :mission => evaluator.mission, :option_set => os, :parent => oing)
        end
      end
    end
  end
end