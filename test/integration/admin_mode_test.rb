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

  test "params admin_mode should be correct" do
    login(@admin)
    get(root_url)
    assert_nil(request.params[:admin_mode])
    get('/admin')
    assert_not_nil(request.params[:admin_mode])
  end

  test "mission dropdown should not be visible in admin mode" do
    login(@admin)
    get(admin_url)


    # exit admin mode link should be visible instead
  end

  test "user's current mission and current_mission should be nil in admin mode" do

  end

  test "exiting admin mode should return user to last mission" do

  end

  test "if user had no last mission, exiting admin mode should still work" do

  end

  test "mission menu item should only appear in admin mode" do

  end

end