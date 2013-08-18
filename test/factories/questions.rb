FactoryGirl.define do
  factory :question do
    code 'somecode'
    qtype_name 'integer'
    name 'the question'
    hint 'some info about the question'
    
    option_set do
      if QuestionType[qtype_name].has_options?
        FactoryGirl.build(:option_set)
      else
        nil
      end
    end
  end
end