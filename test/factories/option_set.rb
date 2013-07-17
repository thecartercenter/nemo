FactoryGirl.define do
  factory :option_set do
    ignore do
      option_names %w(Yes No)
    end
    
    name {
      option_names ? option_names.join : "AnOptionSet"
    }
    
    option_settings {
      opt = option_names
      
      # get the option setting objects, respecting the order they came in
      osg = opt.each_with_index.map{|o,i| OptionSetting.new(:rank => i+1, 
        :option => Option.new(:name_en => o, :mission => get_mission))}
    }
    
    mission { get_mission }
  end
end