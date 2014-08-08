require 'spec_helper'

describe Tagging do
  context "abilities" do
    before do
      @question = create(:question, is_standard: false)
      @tagging = create(:tagging, question: @question)
      @user = create(:user, admin: true)
      @ability = Ability.new(user: @user, mission: get_mission)
    end

    it "should normally allow editing and deleting" do
      expect(@ability).to be_able_to :update, @tagging
      expect(@ability).to be_able_to :destroy, @tagging
    end

    context "if belongs to standard question" do
      before do
        @question.is_standard = true
        @question.save
      end

      it "should not allow deleting" do
        expect(@ability).not_to be_able_to :destroy, @tagging
      end
    end
  end

end
