def find_question_by_code(code)
  question = Question.where(:code => code).first
end

FactoryGirl.define do
  factory :response do
    
    # if no answer_names are submitted, just make it an empty object
    ignore do
      answer_names {}
    end
    
    user {get_user}
    form
    
    # create answers for each answer_name submitted with given
    # question code and value
    answers {
      if answer_names
        answers = answer_names.each_with_index.map { 
          |(k,v),i| 
          question = find_question_by_code(k)
          option = question.options ? question.options.find{|o| o.name_en == v} : nil
          value = question.qtype_name == "text" ? v : nil
          questioning = question.questionings.where(:form_id => form.id).first
            
          # for each answer in string format, create an Answer
          # using option or value, and a questioning
          Answer.new(
            :option => option,
            :value => value,
            :questioning => questioning
          )
        }
      end
      
      answers
    }
  end
end