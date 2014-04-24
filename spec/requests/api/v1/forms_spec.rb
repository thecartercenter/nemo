require "spec_helper"

describe "accessing forms" do
  
  before do
    @mission = FactoryGirl.create(:mission, name: "awesome")
    @form1 = @mission.forms.create(name: "test1", access_level: AccessLevel::PRIVATE)
    @form2 = @mission.forms.create(name: "test2", access_level: AccessLevel::PUBLIC)
    @api_user = FactoryGirl.create(:user)
  end   

  context "Public Forms are returned for a mission" do 
    before do
      get  "/api/v1/missions/awesome/forms.json", {}, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @forms = parse_json(response.body)
    end

    it "should find 1 public form" do
      expect(@forms.size).to eq 1
    end

  end

end
