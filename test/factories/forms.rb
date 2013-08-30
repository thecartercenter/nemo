FactoryGirl.define do
  factory :form do
    ignore do
      question_types []
    end
    
    mission { is_standard ? nil : get_mission }

    name {"some form #{rand(1000000)}"}
    
    questionings do
      question_types.each_with_index.map do |qt, idx|
        FactoryGirl.build(:questioning, :question => FactoryGirl.build(:question, :code => "question#{idx}", :qtype_name => qt))
      end
    end
  end
end