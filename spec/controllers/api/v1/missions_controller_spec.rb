require 'spec_helper'

describe API::V1::MissionsController do

  it "should freaking work" do
  	@headers = Hash.new
    @headers["HTTP_ACCEPT"] = "application/vnd.getelmo.org; version=1"
    get :index, nil, @headers
  end
end
