require 'test_helper'

class MissionChangeRedirectTest < ActionDispatch::IntegrationTest
  setup do
    [User, Mission, Form, OptionSet].each(&:delete_all)
    @other_mission = FactoryGirl.create(:mission, :name => "Other")
    @user = FactoryGirl.create(:user, :role_name => :coordinator)
    @user.change_mission!(get_mission)
  end

  test "user should not be redirected if on object listing and has permission" do
    # add this user to the other mission so the form index will be accessible
    @user.assignments.create!(:mission_id => @other_mission.id, :role => "coordinator")

    assert_redirect_after_mission_change_from(:from => forms_path, :no_redirect => true)
  end

  test "user should be redirected to object listing if viewing object that is mission based and not linked to new current mission" do
    @form = FactoryGirl.create(:form)

    # add this user to the other mission so the form index will be accessible
    @user.assignments.create!(:mission_id => @other_mission.id, :role => "coordinator")

    assert_redirect_after_mission_change_from(:from => form_path(@form), :to => forms_path)
  end

  test "user should be redirected to home screen if was viewing object but redirect to object listing is not permitted" do
    @option_set = FactoryGirl.create(:option_set)

    # add the user to the other mission as an observer so that the option_sets listing won't be allowed
    @user.assignments.create!(:mission_id => @other_mission.id, :role => "observer")

    assert_redirect_after_mission_change_from(:from => option_set_path(@option_set), :to => root_path)
  end

  test "user should be redirected to home screen if current screen not permitted under new mission" do
    @option_set = FactoryGirl.create(:option_set)

    # add the user to the other mission as an observer so that the option_sets listing won't be allowed
    @user.assignments.create!(:mission_id => @other_mission.id, :role => "observer")

    assert_redirect_after_mission_change_from(:from => option_sets_path, :to => root_path)
  end

  private
    def assert_redirect_after_mission_change_from(params)
      login(@user)

      # do a get for the given path
      get(params[:from])
      assert_response(:success)

      # then do a change mission request and make sure the redirect afterward is correct
      # the first redirect should be back to the referrer
      put(user_path(@user), {:user => {:current_mission_id => @other_mission.id}, :changing_current_mission => 1}, {'HTTP_REFERER' => params[:from]})
      assert_redirected_to params[:from]

      # follow the first redirect, which should lead to another redirect to the :to
      follow_redirect!

      # there should never be an error message
      assert_nil(flash[:error], "Should be no error message for mission change redirects")

      # if no_redirect is set then we should expect success right now
      if params[:no_redirect]
        assert_response(:success)

      # else we should have been redirected to the expected destination (:to)
      else
        assert_redirected_to params[:to]

        # follow the second redirect
        follow_redirect!

        # we should now finally get success
        assert_response(:success)
      end
    end
end
