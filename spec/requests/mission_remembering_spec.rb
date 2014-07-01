require 'spec_helper'

describe 'user' do
  before do
    @user = create :user
  end

  context 'if has never viewed a mission and has no assignments' do
    context 'when logging in' do
      before do
        @user.assignments.delete_all
        login_without_redirect @user
      end

      specify { expect(response).to redirect_to basic_root_path }
    end
  end

  context 'if has previously viewed a mission' do
    before do
      expect(@user.assignments.size).to eq 1
      @recent = @user.assignments.first

      User.record_timestamps = false
      @old = create :assignment, user: @user, updated_at: 1.day.ago, created_at: 10.days.ago
      User.record_timestamps = true
    end

    it 'should redirect to that missions root' do
      login_without_redirect @user # First login will go to more recent mission.
      expect(response).to redirect_to mission_root_path(mission_name: @recent.mission.compact_name)

      # This should set last_mission.
      get(mission_root_path(mission_name: @old.mission.compact_name))

      logout
      login_without_redirect @user
      expect(response).to redirect_to mission_root_path(mission_name: @old.mission.compact_name)
    end
  end


  'when exiting admin mode'
    'if has never viewed a mission'
    'if has previously viewed a mission'

end
