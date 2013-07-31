FactoryGirl.define do
  factory :response do
    ignore do
      _answers []
    end
    
    user
    form
    mission { get_mission }
    
    # build answer objects from _answers array
    answers do
      _answers.each_with_index.map do |a, idx|
        Answer.new(:questioning => form.questionings[idx], :value => a)
      end
    end
  end
end