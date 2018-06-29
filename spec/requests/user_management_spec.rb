require 'rails_helper'

describe "user management" do

  let(:user) { create(:user) }
  let(:mission) { get_mission }

  before(:each) { login(user) }

  context "coordinator user" do
    let(:user) { create(:user, role_name: :coordinator) }

    it "can create new user in current mission" do
      test_create_user(get_mission)
    end
  end

  context "admin user" do
    let(:user) { create(:user, admin: true) }

    it "can create new user in mission with role" do
      # User is coord in default mission by default, so can create there
      assert_roles([get_mission, :coordinator], user)
      test_create_user(get_mission)
    end

    context "in another mission" do
      let(:mission) { create(:mission, name: "foo") }

      it "can create new user in any mission" do
        # Can also create in other mission even though no role
        test_create_user(mission)
      end
    end


    it "can adminify user in current mission" do
      user_to_adminify = create(:user, role_name: :enumerator)
      test_adminify_user(user: user_to_adminify, mission: mission, result: true)
    end
  end

  context "non-admin user" do
    let(:user) { create(:user, admin: false) }

    it "cannot adminify themselves" do
      test_adminify_user(user: user, mission: mission, result: false)
    end

    it "cannot adminify other users" do
      user_to_adminify = create(:user, role_name: :enumerator)
      test_adminify_user(user: user_to_adminify, mission: mission, result: false)
    end
  end

  private

  def test_create_user(mission)
    # submission should work
    post("/en/m/#{mission.compact_name}/users",
      params: {
        user: {
          name: "Alan Bob",
          login: "abob",
          assignments_attributes: {"1" => {"mission_id" => mission.id, "role" => "enumerator"}},
          reset_password_method: "print"
        }
      })

    new_u = assigns(:user)
    follow_redirect!
    expect(response).to be_success
    expect(new_u.missions.size).to eq(1)
    expect(new_u.missions[0]).to eq(mission)
  end

  def test_adminify_user(user: create(:user), mission: get_mission, result: false)
    expect(user.admin).to be false
    put(user_path(user, mode: "m", mission: mission), params: {user: { admin: true }})
    follow_redirect!
    expect(response).to be_success
    expect(user.reload.admin).to be result
  end

  # Checks that roles are as specified.
  # Roles should be an array of pairs e.g. [[mission1, role1], [mission2, role2]].
  def assert_roles(expected, user)
    expected = [expected] unless expected.empty? || expected[0].is_a?(Array)
    actual = user.roles
    expected.each do |r|
      expect(actual[r[0]]).to eq(r[1].to_s)
    end
  end
end
