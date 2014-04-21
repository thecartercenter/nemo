require "spec_helper"

describe "accessing forms" do
  
  before do
  	@mission = FactoryGirl.create(:mission, name: "awesome")
    @form1 = @mission.forms.create(name: "test1")
    @form2 = @mission.forms.create(name: "test2")
    @api_user = FactoryGirl.create(:user)
  end   

  context "Forms are returned for a mission" do 
	  before do
	    get  "/api/v1/missions/awesome/forms.json", {}, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
	    @forms = parse_json(response.body)
	  end

	  it "should find 2 forms for the mission" do
	    expect(@forms.size).to eq 2 
	  end

  end

end