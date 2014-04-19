class API::V1::BaseController < ApplicationController
	skip_authorization_check  #for now at least

	before_filter :ensure_access

	protected
	def ensure_access
	  authenticate_or_request_with_http_token do |token, options|
      @api_user = User.find_by_api_key(token)
    end
  end
end
