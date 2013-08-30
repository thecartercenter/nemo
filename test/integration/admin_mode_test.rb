require 'test_helper'

# this class contains tests for the general environment, e.g. admin mode
class AdminModeTest < ActionDispatch::IntegrationTest
  
  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    @nonadmin = FactoryGirl.create(:user)
  end

  test "path helpers still should work after addition of admin routes" do
    @option_set = FactoryGirl.create(:option_set)
    assert_equal("/en/option_sets/#{@option_set.id}", option_set_path(@option_set))
    assert_equal("/en", root_path)
    assert_equal("/en/admin", root_path(:admin_mode => 'admin'))
  end

  test "controller admin_mode helper should work properly" do
    get(root_url)
    assert(!@controller.send(:admin_mode?))
    login(@admin)
    get(root_url)
    assert(!@controller.send(:admin_mode?))
    get(root_url(:admin_mode => 'admin'))
    assert(@controller.send(:admin_mode?))
  end

  test "admin mode should only be available to admins" do
    # login as admin and check for admin mode link
    login(@admin)
    get(root_url)
    assert_select("div#userinfo a.goto_admin_mode")

    # login as other user and make sure not available
    logout
    login(@nonadmin)
    assert_select("div#userinfo a.goto_admin_mode", false)
  end

  test "params admin_mode should be correct" do
    login(@admin)
    get_success(root_url)
    assert_response(:success)
    assert_nil(request.params[:admin_mode])
    get_success('/admin')
    assert_not_nil(request.params[:admin_mode])
  end

  test "admin mode should not be permitted for non-admins" do
    login(@nonadmin)
    get('/admin')
    assert_access_denied
  end

  test "mission dropdown should not be visible in admin mode" do
    login(@admin)
    assert_select('select#user_current_mission_id')
    get('/admin')
    assert_select('select#user_current_mission_id', false)

    # exit admin mode link should be visible instead
    assert_select('a.exit_admin_mode')
  end

  test "users current mission and current_mission should be nil in admin mode" do
    login(@admin)
    assert_not_nil(@admin.current_mission)
    assert_not_nil(@controller.current_mission)

    get('/admin')
    @admin.reload
    assert_nil(@admin.current_mission)
    assert_nil(@controller.current_mission)
  end

  test "mission menu item should only appear in admin mode" do

  end

end