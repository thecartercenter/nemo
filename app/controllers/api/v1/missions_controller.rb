class API::V1::MissionsController < API::V1::BaseController
	skip_authorization_check
	
	def index

		puts "whats up universe"
    render :text => "hi"
  end
end
