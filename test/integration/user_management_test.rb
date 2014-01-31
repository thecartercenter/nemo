require 'test_helper'

# this class contains tests for creating/updating/deleting users/assignments
class UserManagementTest < ActionDispatch::IntegrationTest

  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    @coord = FactoryGirl.create(:user, :role_name => :coordinator)
  end

  test "coordinator can create new user in current mission" do
    login(@coord)
    assert_equal(get_mission, @coord.current_mission)
    test_create_user(@coord, get_mission)
  end

  test "admin can create new user in mission with role" do
    login(@admin)

    # user is coord in default mission by default, so can create there
    assert_equal(get_mission, @admin.current_mission)
    assert_roles([get_mission, :coordinator], @admin)
    test_create_user(@admin, get_mission)
  end

  test "admin can create new user in any mission" do
    # can also create in other mission even though no role
    m = FactoryGirl.create(:mission, :name => 'foo')
    login(@admin)
    @admin.change_mission!(m)
    test_create_user(@admin, m)
  end

  private
    def test_create_user(creator, mission, options = {})
      # submission should work
      post(users_path, :user => {
        :name => 'Alan Bob',
        :login => 'abob',
        :assignments_attributes => {"1" => {"mission_id"=> mission.id, "role" => "staffer", "active" => "1" }},
        :reset_password_method => 'print'
      })

      new_u = assigns(:user)
      follow_redirect!
      assert_response(:success)
      assert_equal(1, new_u.missions.size)
      assert_equal(mission, new_u.missions[0])
    end
end