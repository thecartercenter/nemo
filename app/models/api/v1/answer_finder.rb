class API::V1::AnswerFinder

  def self.for_one(params)
    return [] if self.form_with_permissions(params[:form_id]).blank?
    data = []
    answers = Answer.joins(:response).
                     where(responses: {form_id: params[:form_id]}).
                     where(questionable_id: params[:question_id])
    answers.where(questionable_id: params[:question_id]).each do |answer|
      # Grab only the questions that are public or have nil access_level
      if [nil, AccessLevel::PUBLIC].include?(answer.question.access_level)
        data << {answer_id: answer.id, answer_value: answer.casted_value}
      end
    end
    data
  end

  def self.for_all(params)
    form = self.form_with_permissions(params[:form_id])
    return [] if form.blank?

    data = []
    form.responses.each do |resp|

      answers_data = []
      resp.answers.each do |answer|
        # Grab only the questions that are public or have nil access_level

        if [nil, AccessLevel::PUBLIC].include?(answer.question.access_level)
          answers_data << {question: answer.question.name, answer: answer.casted_value}
        end
      end
      unless answers_data.empty?
        data << {response:{id: resp.id, 
                           submitter: resp.user_id, 
                           created_at: resp.created_at, 
                           updated_at: resp.updated_at,
                           answers: answers_data}}
      end      
    end
    data
  end

  def self.form_with_permissions(form_id)
    # This allows for protected and public forms
    # Todo: check for protected form allowed by api user  
    Form.where(:id => form_id).where("access_level != ?", AccessLevel::PRIVATE).first
  end
end
