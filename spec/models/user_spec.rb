require 'spec_helper'

describe User do

  context 'when user is created' do
    before do
      @user = create(:user)
    end

    it 'should have an api_key generated' do
      expect(@user.api_key).to_not be_blank
    end
  end

  describe 'best_mission' do
    before do
      @user = build(:user)
    end

    context 'with no last mission' do
      context 'with no assignments' do
        before { @user.stub(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end

      context 'with assignments' do
        before do
          @user.stub(:assignments).and_return([
                           build(:assignment, user: @user, updated_at: 2.days.ago),
            @most_recent = build(:assignment, user: @user, updated_at: 1.hour.ago),
                           build(:assignment, user: @user, updated_at: 1.day.ago)
          ])
        end

        it 'should return the mission from the most recently updated assignment' do
          expect(@user.best_mission).to eq @most_recent.mission
        end
      end
    end

    context 'with last mission' do
      before do
        @last_mission = build(:mission)
        @user.stub(:last_mission).and_return(@last_mission)
      end

      context 'and a more recent assignment to another mission' do
        before do
          @user.stub(:assignments).and_return([
            build(:assignment, user: @user, mission: @last_mission, updated_at: 2.days.ago),
            build(:assignment, user: @user, updated_at: 1.hour.ago)
          ])
        end

        specify { expect(@user.best_mission),to eq @last_mission }
      end

      context 'but no longer assigned to last mission' do
        before { @user.stub(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end
    end
  end
end
