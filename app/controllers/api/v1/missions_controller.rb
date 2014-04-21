class API::V1::MissionsController < API::V1::BaseController  
  respond_to :json

  def index
    @missions = Mission.all
    respond_with(@missions, status: :ok)
  end

end
