class API::V1::MissionsController < ApplicationController
	respond_to :json
  def index
  	@missions = Mission.all
  	respond_with(@missions)
  end
end