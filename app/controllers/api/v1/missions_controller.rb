class API::V1::MissionsController < API::V1::BaseController	
	respond_to :json

	def index
		@missons = Mission.all
binding.pry
		respond_with(@missions, status: :ok)
  end
end
