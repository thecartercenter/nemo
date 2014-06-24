require "spec_helper"
require "support/shared_context"

describe "protected form" do
  include_context "api_user_and_mission"
  
  before do
    @form.update_attribute(:access_level, AccessLevel::PROTECTED) 
    @user_no_access = FactoryGirl.create(:user)
    @user_with_access = FactoryGirl.create(:user)
    @form.whitelist_users.create(user_id: @user_with_access.id)
  end

  it "form is protected" do
    @form.access_level == AccessLevel::PROTECTED
  end

  it "form has one user with access" do
    expect(@form.whitelist_users.size).to eql 1 
  end

  context "checking api key" do

    it "should have access" do
      get api_v1_misson_forms_path(mission_name: @mission.name), {}, {'HTTP_AUTHORIZATION' => "Token token=#{@user_with_access.api_key}"}
      @response = parse_json(response.body)
      expect(@response.size).to eql 1
    end

    it "should not have access" do
      get api_v1_misson_forms_path(mission_name: @mission.name), {}, {'HTTP_AUTHORIZATION' => "Token token=#{@user_no_access.api_key}"}
      @response = parse_json(response.body)
      expect(@response.size).to eql 0
    end

  end
end

describe "private form" do
  include_context "api_user_and_mission"

  before do
    @form.update_attribute(:access_level, AccessLevel::PRIVATE)
  end

  it "should not see private forms" do
    get api_v1_misson_forms_path(mission_name: @mission.name), {}, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
    @response = parse_json(response.body)
    expect(@response.size).to eql 0
  end

end
