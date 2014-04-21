require 'spec_helper'

describe API::V1::FormsController do

  before do
    @mission = FactoryGirl.create(:mission, name: "mission1")
    @form1 = @mission.forms.create(name: "test1")
    @form2 = @mission.forms.create(name: "test2")
    api_user = FactoryGirl.create(:user)
    controller.should_receive(:ensure_access).and_return(api_user)
  end

  it "should return status of 200" do
    get  :index, {format: :json, mission_name: "mission1" }
    expect(response.status).to eq 200
  end

  it "should return json" do
    get  :index, {format: :json, mission_name: "mission1" }
    expect(response.content_type).to eq Mime::JSON
  end


end