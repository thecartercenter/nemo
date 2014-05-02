require "spec_helper"

describe "Accessing with API Key" do

  before do
    @user = FactoryGirl.create(:user)
  end

  it "accesses missions with a valid key" do
    get "/api/v1/missions.json", {}, {'HTTP_AUTHORIZATION' => "Token token=#{@user.api_key}"}
    expect(response.status).to be 200
  end

end
