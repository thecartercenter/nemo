require 'will_paginate/array' 
class API::V1::MissionsController < API::V1::BaseController  
  respond_to :json

  def index
    @missions = Mission.all
    paginate json: @missions
  end

end
