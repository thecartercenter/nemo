class API::V1::ResponsesController < API::V1::BaseController

  def index
    data = API::V1::AnswerFinder.for_all(params)
    render json: data.to_json
  end
  
end