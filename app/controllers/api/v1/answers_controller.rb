class API::V1::AnswersController < API::V1::BaseController
  
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
