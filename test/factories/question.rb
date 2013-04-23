FactoryGirl.define do
  factory :question do
    name_eng "Questo"
    code "questo"
    question_type_id { QuestionType.find_by_name("integer").id }
    mission { get_mission }
  end
end