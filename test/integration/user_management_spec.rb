require 'spec_helper'

# this class contains tests for creating/updating/deleting users/assignments
describe 'UserManagement' do

  before do
    @admin = create(:user, :admin => true)
    @coord = create(:user, :role_name => :coordinator)
  end

  it "coordinator can create new user in current mission" do
    login(@coord)
    test_create_user(@coord, get_mission)
  end

  it "admin can create new user in mission with role" do
    login(@admin)

    # user is coord in default mission by default, so can create there
    assert_roles([get_mission, :coordinator], @admin)
    test_create_user(@admin, get_mission)
  end

  it "admin can create new user in any mission" do
    # can also create in other mission even though no role
    m = create(:mission, :name => 'foo')
    login(@admin)
    test_create_user(@admin, m)
  end

  private
    def test_create_user(creator, mission, options = {})
      # submission should work
      post("/en/m/#{mission.compact_name}/users", :user => {
        :name => 'Alan Bob',
        :login => 'abob',
        :assignments_attributes => {"1" => {"mission_id"=> mission.id, "role" => "staffer"}},
        :reset_password_method => 'print'
      })

      new_u = assigns(:user)
      follow_redirect!
      expect(response).to be_success
      expect(new_u.missions.size).to eq(1)
      expect(new_u.missions[0]).to eq(mission)
    end
end