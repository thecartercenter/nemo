require 'will_paginate/array' 
class API::V1::AnswersController < API::V1::BaseController
  
  def index
    answers = API::V1::AnswerFinder.for_one(params)
    paginate json: answers
  end

end
