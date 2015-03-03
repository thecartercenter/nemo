require 'spec_helper'

# Using request spec b/c Authlogic won't work with controller spec
describe UsersController, type: :request do
  before do
    @user = create(:user)
    login(@user)
  end

  context 'when updating preferred language' do
    before do
      put(user_path(@user, :locale => 'en'), :user => {:pref_lang => 'fr'})
    end

    it 'should redirect back to profile but in french' do
      assert_redirected_to(edit_user_path(@user, :locale => 'fr'))
    end

    after do
      I18n.locale = :en
    end
  end

  context 'when not updating preferred language and preferred language doesnt match locale' do
    before do
      put(user_path(@user, :locale => 'fr'), :user => {:name => 'Foobar'})
    end

    it 'should not change the locale on redirect' do
      assert_redirected_to(edit_user_path(@user, :locale => 'fr'))
    end
  end

  describe 'update' do
    context 'when updating admin profile in unassigned mission' do
      before do
        mission = create(:mission)
        user = create(:user, admin: true, role_name: 'coordinator')
        login(user)

        put(user_path(user, :locale => 'en', mode: 'm', mission_name: mission.compact_name), :user => {:name => 'Test'})
      end

      it 'should be successful' do
        expect(response.status).to eq(302)
        user = assigns(:user)
        expect(user.name).to eq 'Test'
      end

    end
  end
end
