FactoryGirl.define do
  factory :option_set do
    ignore do
      option_names true
    end
    
    name "YesNo"
    options {
      opt = option_names || %w(Yes No)
      opt.each_with_index.map{|o,i| Option.create(:value => i+1, :name_eng => o, :mission => get_mission)}
    }
    ordering "value_asc"
    mission { get_mission }
  end
end