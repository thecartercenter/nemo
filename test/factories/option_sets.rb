FactoryGirl.define do
  factory :option_set do
    ignore do
      option_names %w(Yes No)
    end

    sequence(:name) { |n| "Option Set #{n}" }
    mission { is_standard ? nil : get_mission }
    association :root_node, factory: :option_node_with_children

    optionings do
      # make the optioning objects, respecting the order they came in
      option_names.each_with_index.map do |name, i|
        Optioning.new(:rank => i + 1, :option => Option.new(:name => name, :mission => mission), :mission => mission)
      end
    end

    factory :empty_option_set do
      association :root_node, factory: :option_node_with_no_children
    end

    factory :multilevel_option_set do
      ignore do
        level_names ['kingdom', 'species']

        # must give two levels of option names
        option_names [['animal', ['cat', 'dog']], ['plant', ['pine', 'tulip']]]
      end

      mission { is_standard ? nil : get_mission }
      multi_level true
      association :root_node, factory: :option_node_with_grandchildren

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
end