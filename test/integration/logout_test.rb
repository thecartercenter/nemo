require 'test_helper'

class LogoutTest < ActionDispatch::IntegrationTest

  setup do
    @user = FactoryGirl.create(:user, :admin => true)
  end

  test 'redirect after logout from basic mode should be correct' do
    login(@user)
    check_logout_link_and_redirect
  end

  test 'redirect after logout from mission mode should be correct' do
    login(@user)
    get("/en/m/#{get_mission.compact_name}")
    assert_response(:success)
    check_logout_link_and_redirect
  end

  test 'redirect after logout from admin mode should be correct' do
    login(@user)
    get('/en/admin')
    assert_response(:success)
    check_logout_link_and_redirect
  end

  private

  def check_logout_link_and_redirect
    assert_select('#logout_button[href=/en/logout]', true)
    delete('/en/logout')
    assert_redirected_to('/en/logged-out')
  end
end

