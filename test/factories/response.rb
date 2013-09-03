def find_question_by_code(code)
  question = Question.where(:code => code).first
end

def find_option_by_name(name)
  option = Option.where("_name" => name).first
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
          
          # find the question by given key
          question = find_question_by_code(k)
          
          # find that question's associated options and locate option with the given value, else option is null
          option = question.options ? question.options.find{|o| o.name_en == v} : nil
          
          # if the question's question type is text, set text value value to v.
          value = question.qtype_name == "text" ? v : nil
          
          # set questioning to questioning within question where form id is the one passed in
          questioning = question.questionings.where(:form_id => form.id).first
            
          # for each answer in string format, create an Answer
          # using option or value, and a questioning
          a = Answer.new(
            :option => option,
            :value => value,
            :questioning => questioning
          )
          
          # if value is an array, the answer submitted consists of choice(s)
          if v.kind_of?(Array)
            choices = Array.new            
            v.each do |c|
              a.choices << Choice.new(:option => find_option_by_name(c))
            end
          end
          a
        }
      end
      
      answers
    }
    
    before(:create) do |o,e|
      e.generate_duplicate_signature
    end      
  end
end