class API::V1::AnswersController < API::V1::BaseController
  def one
   # Form.last.responses.where(form_id= 4).first.answers.where(questionable_id: params[:question_id])

    responses = Form.find(params[:form_id]).responses
    data = []
    responses.each do |resp|
      data << resp.answers.answers.map(&:value)
    end
  #  Questioning.where(form_id: params[:form_id]).where(question_id:params[:question_id])
    render json: data.to_json
  end

  def all
    #Form.where(:form_id => params[:form_id]).responses.collect()
  end
end
