class API::V1::AnswersController < API::V1::BaseController
  
  def index
    answers = API::V1::AnswerFinder.for_one(params)
    render json: answers
  end

end
