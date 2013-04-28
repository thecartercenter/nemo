FactoryGirl.define do
  factory :option_set do
    ignore do
      option_names %w(Yes No)
    end
    
    name "YesNo"
    options {
      opt = option_names
      opt.each_with_index.map{|o,i| Option.create(:value => i+1, :name_en => o, :mission => get_mission)}
    }
    ordering "value_asc"
    mission { get_mission }
  end
end