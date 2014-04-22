class API::V1::BaseController < ApplicationController
	skip_authorization_check  #for now at least

	before_filter :authenticate

	protected

	def authenticate
	  authenticate_token || render_unauthorized
	end

	def authenticate_token
	  authenticate_or_request_with_http_token do |token, options|
      @api_user = User.find_by_api_key(token)
    end
  end

  def render_unauthorized
  	self.headers["WWW-Authenticate"] = "Token realm='Application'"
    
    respond_to do |format|
    	format.json { render json: 'Bad Credentials', status: 401}
    end
  end
  
end
