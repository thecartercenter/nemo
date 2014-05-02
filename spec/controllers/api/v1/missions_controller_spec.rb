require 'spec_helper'

describe API::V1::MissionsController do

  context "when user has access" do

    before do
      @mission1 = FactoryGirl.create(:mission, name: "mission 1")
      @mission2 = FactoryGirl.create(:mission, name: "mission 2")
      api_user = FactoryGirl.create(:user)
      controller.should_receive(:authenticate_token).and_return(api_user)
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
      missions = parse_json(response.body)
      expect(missions.first[:name]).to eq @mission1.name
    end

  end


  context "when user does not have access" do

    before do
      controller.should_receive(:authenticate_token).and_return(false)
    end

    it "should return 401" do
      get :index, {format: :json}  
      expect(response.status).to eq 401
    end

  end

end
