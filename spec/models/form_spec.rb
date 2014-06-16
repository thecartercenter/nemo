require "spec_helper"

describe Form do

  context "API User" do
    before do
      @api_user = FactoryGirl.create(:user)
      @mission = FactoryGirl.create(:mission, name: "test mission")
      @form = FactoryGirl.create(:form, mission: @mission, name: "something", access_level: AccessLevel::PROTECTED)  
      @form.whitelist_users.create(user_id: @api_user.id)
    end
 
    it "should return true for user in whitelist" do
      expect(@form.api_user_id_can_see?(@api_user.id)).to be_true
    end

    it "should return false for user not in whitelist" do
      other_user = FactoryGirl.create(:user)
      expect(@form.api_user_id_can_see?(other_user.id)).to be_false
    end
  end

end
