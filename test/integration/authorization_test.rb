require 'test_helper'

class AuthorizationTest < ActionDispatch::IntegrationTest

  setup do
    @other_mission = FactoryGirl.create(:mission, :name => "Other")
  end

  test "guests can see login page" do
    assert_can_access(nil, '/en/login')
  end

  test "user can login and see welcome screen" do
    @user = FactoryGirl.create(:user)
    assert_can_access(@user, '/en')
  end

  test "anybody can logout" do
    @user = FactoryGirl.create(:user)
    # even guest can go to the logout page and get a sensible response (reduced confusion if back button used)
    assert_can_access(nil, '/en/logout', :redirected_to => '/en/logged-out')
    # logged in user can logout
    assert_can_access(@user, '/en/logout', :redirected_to => '/en/logged-out')
  end

  test "guest redirected to login page with message if unauthorized" do
    assert_can_access(nil, '/en/admin/missions', :redirected_to => '/en/login')
    assert_select("div.alert-danger", /must login/)
  end

  test "user redirected to root if unauthorized" do
    @user = FactoryGirl.create(:user, :role_name => :observer)
    login(@user)
    assert_cannot_access(@user, '/en/admin/missions')
  end

  test "coordinator can only view forms for current mission" do
    @user = FactoryGirl.create(:user, :role_name => :coordinator)
    @form1 = FactoryGirl.create(:form, :mission_id => get_mission.id)
    @form2 = FactoryGirl.create(:form, :mission_id => @other_mission.id)
    assert_can_access(@user, '/en/m/missionwithsettings/forms')
  end

  test "observer can update own name" do
    user = FactoryGirl.create(:user, :role_name => :observer, :name => 'foo')
    login(user)
    put(user_path(user), :user => {:name => 'bar'})
    assert_response(302) # redirected
    assert_equal('bar', user.reload.name)
  end

  test "observer cant update own role" do
    user = FactoryGirl.create(:user, :role_name => :observer)
    login(user)
    assignments_attributes = user.assignments.first.attributes.slice(*%w(id mission_id)).merge('role' => 'staffer')
    put(user_path(user), :user => {:assignments_attributes => [assignments_attributes]})
    assert_equal(true, assigns(:access_denied))
    assert_equal('observer', user.reload.assignments.first.role)
  end

  test "coordinator can update role of user in same mission" do
    coord = FactoryGirl.create(:user, :role_name => :coordinator)
    obs = FactoryGirl.create(:user, :role_name => :observer)
    login(coord)

    # Get attributes for request to change observer role to staffer.
    assignments_attributes = obs.assignments.first.attributes.slice(*%w(id mission_id)).merge('role' => 'staffer')

    put("/en/m/missionwithsettings/users/#{obs.id}", :user => {:assignments_attributes => [assignments_attributes]})
    assert_nil(assigns(:access_denied))
    assert_equal('staffer', obs.reload.assignments.first.role)
  end

  private
    # logs in a user and attempts to load the given path
    # errors if the response is not 200
    def assert_can_access(user, path, options = {})
      login(user) if user

      get(path)

      if options[:redirected_to]
        # check to make sure we were redirected properly
        assert_redirected_to(options[:redirected_to])
        # follow the redirect and look for a message
        follow_redirect!
      end

      assert_response(options[:expected_response] || :success)
    end

    def assert_cannot_access(user, path, options = {})
      login(user) if user
      get(path)
      assert_redirected_to('/en')
      assert_match(flash[:error], /not authorized/)
    end
end