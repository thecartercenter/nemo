class API::V1::AnswersController < API::V1::BaseController
  
  def index
    data = API::V1::AnswerFinder.for_one(params)
    render json: data.to_json
  end

end
