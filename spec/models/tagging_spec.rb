require 'spec_helper'

describe Tagging do
  describe "abilities" do
    subject(:ability) do
      user = double("Admin User", admin?: true).as_null_object
      Ability.new(user: user, mission: get_mission)
    end

    before do
      @question = build(:question, is_standard: false)
      @tagging = build(:tagging, question: @question)
    end

    it { should be_able_to :update, @tagging }
    it { should be_able_to :destroy, @tagging }

    context "if belongs to standard question" do
      before { @question.is_standard = true }

      it { should be_able_to :update, @tagging }
      it { should_not be_able_to :destroy, @tagging }
    end
  end

end
