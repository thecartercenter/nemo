require "spec_helper"
require "support/shared_context"

describe "protected form" do
  include_context "api_user_and_mission"

  before do
    @form.update_attribute(:access_level, 'protected')
    @user_no_access = FactoryGirl.create(:user)
    @user_with_access = FactoryGirl.create(:user)
    @form.whitelist_users.create(user_id: @user_with_access.id)
  end

  it "form is protected" do
    @form.access_level == 'protected'
  end

  it "form has one user with access" do
    expect(@form.whitelist_users.size).to eql 1
  end

  context "checking api key" do

    it "should have access" do
      do_api_request(:forms, :user => @user_with_access)
      @response = parse_json(response.body)
      expect(@response.size).to eql 1
    end

    it "should not have access" do
      do_api_request(:forms, :user => @user_no_access)
      @response = parse_json(response.body)
      expect(@response.size).to eql 0
    end

  end
end

describe "private form" do
  include_context "api_user_and_mission"

  before do
    @form.update_attribute(:access_level, 'private')
  end

  it "should not see private forms" do
    do_api_request(:forms)
    @response = parse_json(response.body)
    expect(@response.size).to eql 0
  end
end
