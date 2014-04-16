require 'spec_helper'

describe API::V1::MissionsController do

	before do
		#@headers = Hash.new
    #@headers["HTTP_ACCEPT"] = "application/vnd.getelmo.org; version=1"
	end

  it "should get the index" do
    get "/v1/missions.json"
    expect(response.status).to == 200
  end

end

