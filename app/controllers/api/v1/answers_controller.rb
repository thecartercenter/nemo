class API::V1::AnswersController < API::V1::BaseController
  
  def one
    data = API::V1::Answers.for_one(params)
    render json: data.to_json
  end

  def all
    data = API::V1::Answers.for_all(params)
    render json: data.to_json
  end

end
