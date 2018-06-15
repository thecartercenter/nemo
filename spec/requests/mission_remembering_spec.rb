require 'rails_helper'

describe 'user' do
  before do
    @user = create :user, admin: true
  end

  context 'if has assignments' do
    before do
      login_without_redirect @user
    end

    it 'should be redirected to assignment mission' do
      expect(response).to redirect_to mission_root_path(mission_name: @user.assignments.first.mission.compact_name)
    end
  end


  context 'if has never viewed a mission and has no assignments' do
    before do
      @user.assignments.delete_all
      login_without_redirect @user
    end

    it 'should be redirected to basic root on login' do
      expect(response).to redirect_to basic_root_path
    end

    it 'should be linked to basic path for admin mode exit' do
      get admin_root_path
      expect(response).to be_success
      assert_select(%Q{a.admin-mode[href="#{basic_root_path}"]}, true)
    end
  end

  shared_examples_for 'redirects to viewed mission' do
    before do
      login_without_redirect @user # First login will go to more recent mission.
      #expect(response).to redirect_to mission_root_path(mission_name: @recent.mission.compact_name)
      @other_mission = create(:mission)

      # This should set last_mission.
      get(mission_root_path(mission_name: @other_mission.compact_name))

      logout
      login_without_redirect @user
    end

    it 'should be redirected to that missions root on login' do
      expect(response).to redirect_to mission_root_path(mission_name: @other_mission.compact_name)
    end

    it 'should be linked to that missions path for admin mode exit' do
      get admin_root_path
      expect(response).to be_success
      path = mission_root_path(mission_name: @other_mission.compact_name)
      assert_select(%Q{a.admin-mode[href="#{path}"]}, true)
    end
  end

  context 'if has previously viewed mission' do
    context 'if has assignments' do
      before do
        expect(@user.assignments.size).to eq 1
        @recent = @user.assignments.first
      end

      it_behaves_like 'redirects to viewed mission'
    end

    context 'if has no assignments' do
      before do
        @user.assignments.delete_all
      end

      it_behaves_like 'redirects to viewed mission'
    end
  end
end
