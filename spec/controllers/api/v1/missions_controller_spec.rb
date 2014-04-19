require 'spec_helper'

describe API::V1::MissionsController do

  before do
    @mission1 = FactoryGirl.create(:mission, name: "mission 1")
    @mission2 = FactoryGirl.create(:mission, name: "mission 2")
    controller.should_receive(:ensure_access).and_return(FactoryGirl.create(:user))
  end

  it "should return json" do
    get :index, {format: :json} 
    expect(response.content_type).to eq Mime::JSON
  end

  it "should return 200" do
    get :index, {format: :json}  
    expect(response.status).to eq 200
  end

  it "should return array of missions and match first name" do
    get :index, {format: :json}  
    missions = JSON.parse(response.body, symbolize_names: true)
    expect(missions.first[:name]).to eq @mission1.name
  end

end
