require 'test_helper'

# this class contains tests for the general environment, e.g. admin mode
class AdminModeTest < ActionDispatch::IntegrationTest

  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    @nonadmin = FactoryGirl.create(:user)
  end

  test "admin mode link works" do
    login(@admin)
    assert_select('a.admin-mode[href=/en/admin]', true)
    get('/en/admin')
    assert_response(:success)
  end

  test "controller admin_mode helper should work properly" do
    get(login_url)
    assert_equal(false, @controller.send(:admin_mode?))

    login(@admin)
    get(basic_root_url)
    assert_equal(false, @controller.send(:admin_mode?))

    get(admin_root_url(:mode => 'admin'))
    assert_equal(true, @controller.send(:admin_mode?))
  end

  test "admin mode should only be available to admins" do
    # login as admin and check for admin mode link
    login(@admin)
    get(basic_root_url)
    assert_select("div#userinfo a.admin-mode")

    # login as other user and make sure not available
    logout
    login(@nonadmin)
    assert_select("div#userinfo a.admin-mode", false)
  end

  test "params admin_mode should be correct" do
    login(@admin)
    get_success(basic_root_url)
    assert_response(:success)
    assert_nil(request.params[:mode])
    get_success('/en/admin')
    assert_equal('admin', request.params[:mode])
  end

  test "admin mode should not be permitted for non-admins" do
    login(@nonadmin)
    get('/en/admin')
    assert_access_denied
  end

  test "mission dropdown should not be visible in admin mode" do
    login(@admin)
    assert_select('form#change_mission')
    get_success('/en/admin')

    assert_select('form#change_mission', false)

    # exit admin mode link should be visible instead
    assert_select('a.exit-admin-mode')
  end

  test "creating a form in admin mode should create a standard form" do
    login(@admin)
    post_via_redirect(forms_path(:mode => 'admin', :mission_name => nil),
      {:form => {:name => 'Foo', :smsable => false}})
    f = assigns(:form)
    assert_nil(f.mission)
    assert(f.is_standard?, 'new form should be standard')
  end

  test "creating a question in admin mode should create a standard question" do
    login(@admin)
    post_via_redirect(questions_path(:mode => 'admin', :mission_name => nil),
      {:question => {:code => 'Foo', :qtype_name => 'integer', :name_en => 'Stuff'}})
    q = Question.order('created_at').last
    assert_nil(q.mission)
    assert(q.is_standard?, 'new question should be standard')
  end

  test "valid delete of mission" do
    @mission = get_mission
    login(@admin)

    assert_difference('Mission.count', -1) do
      delete_via_redirect(mission_path(@mission.id, :mode => 'admin'))
    end
  end
end
