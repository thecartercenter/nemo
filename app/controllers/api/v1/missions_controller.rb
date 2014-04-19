class API::V1::MissionsController < API::V1::BaseController	
	respond_to :json

	def index
		#TODO: Find all missions if api_user is valid
		@missions = Mission.all
		respond_with(@missions, status: :ok)
  end
end
