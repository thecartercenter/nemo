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
      expect(response).to redirect_to(edit_user_path(@user, :locale => 'fr'))
    end

    after do
      I18n.locale = :en
    end
  end

  context 'when not updating preferred language and preferred language doesnt match locale' do
    before do
      put(user_path(@user, :locale => 'fr'), :user => {:name => 'Foobar'})
    end

    it 'should not change the locale on redirect', :investigate do
      expect(response).to redirect_to(edit_user_path(@user, :locale => 'fr'))
    end
  end
end
