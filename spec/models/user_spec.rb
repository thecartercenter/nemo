require 'spec_helper'

describe User do

  context "when user is created" do

    before do
      @user = FactoryGirl.create(:user)
    end

    it "should have an api_key generated" do
      expect(@user.api_key).to_not be_blank
    end

  end

end
