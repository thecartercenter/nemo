require 'will_paginate/array' 
class API::V1::ResponsesController < API::V1::BaseController

  def index
    responses = API::V1::AnswerFinder.for_all(params)
    paginate json: responses, each_serializer: API::V1::ResponseSerializer
  end
  
end
