class API::V1::Answers

  def self.for_one(params)
    responses = Form.find(params[:form_id]).responses
    data = []
    responses.each do |resp|
      resp.answers.where(questionable_id: params[:question_id]).each do |answer|
        data << {question_id: answer.question.id, 
                 question: answer.question._name,
                 answer_id: answer.id,  
                 answer: answer.value}
      end
    end
    data
  end

  def self.for_all(params)
    responses = Form.find(params[:form_id]).responses
    data = []
    responses.each do |resp|
      resp.answers.each do |answer|
        data << {question: answer.question._name, answer: answer.value}
      end
    end
    data
  end
 
end