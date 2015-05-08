require 'spec_helper'

describe 'Logout' do

  before do
    @user = create(:user, :admin => true)
  end

  it "redirect after logout from basic mode should be correct" do
    login(@user)
    check_logout_link_and_redirect
  end

  it "redirect after logout from mission mode should be correct" do
    login(@user)
    get("/en/m/#{get_mission.compact_name}")
    expect(response).to be_success
    check_logout_link_and_redirect
  end

  it "redirect after logout from admin mode should be correct" do
    login(@user)
    get('/en/admin')
    expect(response).to be_success
    check_logout_link_and_redirect
  end

  private

  def check_logout_link_and_redirect
    assert_select('#logout_button[href=/en/logout]', true)
    delete('/en/logout')
    assert_redirected_to('/en/logged-out')
  end
end

