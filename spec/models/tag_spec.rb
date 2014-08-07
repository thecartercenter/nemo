require 'spec_helper'
require 'cancan/matchers'

describe Tag do
  it 'should create cleanly' do
    create(:tag)
  end

  context "if copy of standard object" do
    before do
      @tag = create(:tag)
      allow(@tag).to receive_messages(standard_copy?: true)
      @user = create(:user, admin: true)
      @ability = Ability.new(user: @user, mission: get_mission)
    end

    it "should not allow editing" do
      expect(@ability).not_to be_able_to :update, @tag
    end
  end
end
