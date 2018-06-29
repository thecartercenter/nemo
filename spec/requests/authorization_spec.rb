require 'rails_helper'

describe 'authorization' do

  let(:mission1) { get_mission }
  let(:mission2) { create(:mission, name: "Other") }

  it "guests can see login page" do
    assert_can_access(nil, '/en/login')
  end

  it "user can login and see welcome screen" do
    user = create(:user)
    assert_can_access(user, '/en')
  end

  it "anybody can logout" do
    user = create(:user)
    # even guest can go to the logout page and get a sensible response (reduced confusion if back button used)
    assert_can_access(nil, '/en/logout', method: :delete, redirected_to: '/en/logged-out')
    # logged in user can logout
    assert_can_access(user, '/en/logout', method: :delete, redirected_to: '/en/logged-out')
  end

  it "guest redirected to login page with message if unauthorized" do
    assert_can_access(nil, '/en/admin/missions', redirected_to: '/en/login')
    assert_select("div.alert-danger", /must login/)
  end

  it "user redirected to unauthorized page if unauthorized" do
    user = create(:user, role_name: :enumerator)
    assert_cannot_access(user, '/en/admin/missions') # This assertion checks redirect

    follow_redirect!
    expect(response).to be_success
    expect(flash[:error]).to be_nil # Not needed since we have unauth page
  end

  it "coordinator can only view forms for current mission" do
    user = create(:user, role_name: :coordinator)
    create(:form, mission_id: mission1.id)
    create(:form, mission_id: mission2.id)
    assert_can_access(user, "/en/m/#{mission1.compact_name}/forms")
    assert_cannot_access(user, "/en/m/#{mission2.compact_name}/forms")
  end

  it "enumerator can update own name" do
    user = create(:user, role_name: :enumerator, name: 'foo')
    login(user)
    put(user_path(user), params: {user: {name: 'bar'}})
    assert_response(302) # redirected
    expect(user.reload.name).to eq('bar')
  end

  it "enumerator cant update own role" do
    user = create(:user, role_name: :enumerator)
    login(user)
    assignments_attributes = user.assignments.first.attributes.slice(*%w(id mission_id)).merge('role' => 'staffer')
    put(user_path(user), params: {user: {assignments_attributes: [assignments_attributes]}})
    expect(assigns(:access_denied)).to eq(true)
    expect(user.reload.assignments.first.role).to eq('enumerator')
  end

  it "coordinator can update role of user in same mission" do
    coord = create(:user, role_name: :coordinator)
    obs = create(:user, role_name: :enumerator)
    login(coord)

    # Get attributes for request to change enumerator role to staffer.
    assignments_attributes = obs.assignments.first.attributes.slice(*%w(id mission_id)).merge('role' => 'staffer')

    put(user_path(obs), params: {user: {assignments_attributes: [assignments_attributes]}})
    expect(assigns(:access_denied)).to be_nil
    expect(obs.reload.assignments.first.role).to eq('staffer')
  end

  describe 'admin' do
    let(:admin) { create(:user, admin: true) }

    before do
      login(admin)
    end

    it 'should be able to edit self in basic mode' do
      get(edit_user_path(admin, mode: nil, mission_name: nil))
      assert_response :success
    end

    context 'with an assignment with empty role' do
      before do
        admin.assignments.delete_all
      end

      let(:assignment_without_role) { build(:assignment, user: admin, role: '') }
      let(:empty_assignment_attributes) { assignment_without_role.attributes.slice(*%w(id mission_id role)) }
      let(:admin_new_name) { 'New name' }

      it 'still can update self' do
        put(user_path(admin), params: {user: {name: admin_new_name, assignments_attributes: [empty_assignment_attributes]}})

        assert_response(302) # redirected
        expect(admin.reload.name).to eq admin_new_name
      end
    end
  end

  private
    # logs in a user and attempts to load the given path
    # errors if the response is not 200
    def assert_can_access(user, path, options = {})
      login(user) if user

      send(options[:method] || :get, path)

      if options[:redirected_to]
        # check to make sure we were redirected properly
        expect(response).to redirect_to(options[:redirected_to])
        # follow the redirect and look for a message
        follow_redirect!
      end

      expect(response).to be_success
    end

    def assert_cannot_access(user, path, options = {})
      login(user) if user
      send(options[:method] || :get, path)
      expect(response).to redirect_to('/en/unauthorized')
    end
end
