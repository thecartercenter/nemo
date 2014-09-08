require 'test_helper'

class MissionChangeRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @mission1 = FactoryGirl.create(:mission, :name => "Mission1")
    @mission2 = FactoryGirl.create(:mission, :name => "Mission2")
    @user = FactoryGirl.create(:user, :mission => @mission1, :role_name => :coordinator)
  end

  test "user should not be redirected if on object listing and has permission" do
    # add this user to the other mission so the form index will be accessible
    @user.assignments.create!(:mission => @mission2, :role => "coordinator")
    assert_redirect_after_mission_change_from(:from => '/en/m/mission1/forms', :no_redirect => true)
  end

  test "user should be redirected to object listing if viewing object that is mission based and not linked to new current mission" do
    # Add this user to the other mission so the form index will be accessible.
    @user.assignments.create!(:mission => @mission2, :role => "coordinator")

    # Try multiple object types.
    %w(form option_set).each do |type|
      @obj = FactoryGirl.create(type, mission: @mission1)

      path_chunk = type.gsub('_', '-') << 's'
      assert_redirect_after_mission_change_from(
        from: "/en/m/mission1/#{path_chunk}/#{@obj.id}",
        :to => "/en/m/mission2/#{path_chunk}")
    end
  end

  test "user should be redirected to home screen if was viewing object but redirect to object listing is not permitted" do
    @option_set = FactoryGirl.create(:option_set, :mission => @mission1)

    # add the user to the other mission as an observer so that the option_sets listing won't be allowed
    @user.assignments.create!(:mission => @mission2, :role => "observer")

    assert_redirect_after_mission_change_from(
      :from => "/en/m/mission1/option-sets/#{@option_set.id}",
      :to => "/en/m/mission2")
  end

  test "user should be redirected to home screen if current screen not permitted under new mission" do
    # add the user to the other mission as an observer so that the option_sets listing won't be allowed
    @user.assignments.create!(:mission => @mission2, :role => "observer")

    assert_redirect_after_mission_change_from(
      :from => "/en/m/mission1/option-sets",
      :to => "/en/m/mission2")
  end

  test "missionchange flag should be removed cleanly if it's the only query string arg" do
    get('/en?missionchange=1')
    assert_redirected_to('/en')
  end

  test "missionchange flag should be removed cleanly if it's the first of several args" do
    get('/en?missionchange=1&foo=bar')
    assert_redirected_to('/en?foo=bar')
  end

  test "missionchange flag should be removed cleanly if it's the last of several args" do
    get('/en?foo=bar&missionchange=1')
    assert_redirected_to('/en?foo=bar')
  end

  test "missionchange flag should be removed cleanly if it's in the middle several args" do
    get('/en?foo=bar&missionchange=1&bar=foo')
    assert_redirected_to('/en?foo=bar&bar=foo')
  end

  private
    def assert_redirect_after_mission_change_from(params)
      login(@user)

      # do a get for the given path
      get(params[:from])
      assert_response(:success)

      # Then do a request for the same path but different mission
      # and make sure the redirect afterward is correct
      get(params[:from].gsub('mission1', 'mission2'), :missionchange => 1)

      # there should never be an error message
      assert_nil(flash[:error], "Should be no error message for mission change redirects")

      # We should expect a redirect to remove the missionchange param
      assert_response(:redirect)
      follow_redirect!
      assert_no_match(/missionchange/, request.url)

      if params[:no_redirect]
        assert_response(:success)

      else
        assert_redirected_to params[:to]

        # follow the second redirect
        follow_redirect!

        # we should now finally get success
        assert_response(:success)
      end
    end
end
