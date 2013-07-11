FactoryGirl.define do
  factory :option_set do
    ignore do
      option_names %w(Yes No)
    end
    
    name "YesNo"
    options {
      opt = option_names
      
      # get the option objects
      options = opt.each_with_index.map{|o,i| Option.new(:value => i+1, :name_en => o, :mission => get_mission)}
      
      # randomize the array to make sure things get sorted properly later
      options = options.shuffle
      
      # now save the options
      options.each{|o| o.save!}
      
      options
    }
    
    ordering "value_asc"
    mission { get_mission }
  end
end