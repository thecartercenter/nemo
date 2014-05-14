class API::V1::AnswerFinder

  def self.for_one(params)
    responses = Form.find(params[:form_id]).responses
    data = []
    answers = Answer.joins(:response).where(responses: {form_id: params[:form_id]}).where(questionable_id: params[:question_id])
    answers.where(questionable_id: params[:question_id]).each do |answer|
      data << {answer_id: answer.id, answer_value: answer.casted_value}
    end
    data
  end

  def self.for_all(params)
    responses = Form.find(params[:form_id]).responses
    data = []
    responses.each do |resp|

      answers_data = []
      resp.answers.each do |answer|
        answers_data << {question: answer.question.name, answer: answer.casted_value}
      end
      data << {response:{id: resp.id, 
                         submitter: resp.user_id, 
                         created_at: resp.created_at, 
                         updated_at: resp.updated_at,
                         answers: answers_data}}      
    end
    data
  end
  
  private 

  def protected_and_allowed(form) 
    form_protected?(form) && user_allowed?(form)
  end

  def form_protected?(form)
    form.access_level == AccessLevel::PROTECTED     
  end

  def user_allowed?(form)
    form.whitelist_users.pluck(:user_id).include?(@api_user.id)
  end

end
