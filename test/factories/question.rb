FactoryGirl.define do
  factory :question do
    name_en "Questo"
    code "questo"
    qtype_name "integer"    
    mission { get_mission }
    
    # create questioning for each form in forms attribute
    after(:create) do |question, evaluator|
      question.forms.each { |f| question.questionings.create(:form => f) }
    end
    
  end
end