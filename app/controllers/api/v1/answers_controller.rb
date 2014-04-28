class API::V1::AnswersController < API::V1::BaseController
  
  def one
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
    render json: data.to_json
  end

  def all
    responses = Form.find(params[:form_id]).responses
    data = []
    responses.each do |resp|
      resp.answers.each do |answer|
        data << {question: answer.question._name, answer: answer.value}
      end
    end
    render json: data.to_json
  end
  
end
