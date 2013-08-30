require 'test_helper'

# this class contains tests for the general environment, e.g. admin mode
class AdminModeTest < ActionDispatch::IntegrationTest
  
  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    @nonadmin = FactoryGirl.create(:user)
  end

  test "admin mode should only be available to admins" do
    # login as admin and check for admin mode link
    login(@admin)
    get(root_url)
    assert_select("div#userinfo a.admin_mode")

    # login as other user and make sure not available
    logout
    login(@nonadmin)
    assert_select("div#userinfo a.admin_mode", false)
  end

  test "mission menu item should only appear in admin mode" do

  end

end