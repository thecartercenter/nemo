require 'spec_helper'

describe API::V1::MissionsController do

  before do
  	@headers = Hash.new
    @headers["HTTP_ACCEPT"] = "application/vnd.getelmo.org; version=1"
    FactoryGirl.create(:mission, name: "mission 1")
    FactoryGirl.create(:mission, name: "mission 2")
  end

  it "should return json" do
    get "index", {format: :json}, @headers
    expect(response.content_type).to eq Mime::JSON
  end

  it "should return 200" do
    get :index, {format: :json}, @headers  	
    expect(response.status).to eq 200
  end

  it "should gimmie something" do
    get :index, {format: :json}, @headers 
    res = JSON.parse(response.body) 	
    expect(response.status).to eq res 	
  end
end
