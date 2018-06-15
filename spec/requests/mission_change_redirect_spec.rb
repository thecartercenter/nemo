require "rails_helper"

describe "redirect on mission change" do

  before do
    @mission1 = create(:mission, name: "Mission1")
    @mission2 = create(:mission, name: "Mission2")
    @user = create(:user, mission: @mission1, role_name: :coordinator)
  end

  it "user should not be redirected if on object listing and has permission" do
    # add this user to the other mission so the form index will be accessible
    @user.assignments.create!(mission: @mission2, role: "coordinator")
    assert_redirect_after_mission_change_from(from: "/en/m/mission1/forms", no_redirect: true)
  end

  it "user should be redirected to object listing if viewing object that is mission based and not linked to new current mission" do
    # Add this user to the other mission so the form index will be accessible.
    @user.assignments.create!(mission: @mission2, role: "coordinator")

    # Try multiple object types.
    %w(form option_set).each do |type|
      @obj = create(type, mission: @mission1)

      path_chunk = type.gsub("_", "-") << "s"
      assert_redirect_after_mission_change_from(
        from: "/en/m/mission1/#{path_chunk}/#{@obj.id}",
        to: "/en/m/mission2/#{path_chunk}")
    end
  end

  it "user should be redirected to home screen if was viewing object but redirect to object listing is not permitted" do
    @option_set = create(:option_set, mission: @mission1)

    # add the user to the other mission as an enumerator so that the option_sets listing won't be allowed
    @user.assignments.create!(mission: @mission2, role: "enumerator")

    assert_redirect_after_mission_change_from(
      from: "/en/m/mission1/option-sets/#{@option_set.id}",
      to: "/en/m/mission2")
  end

  it "user should be redirected to home screen if viewing new response but form not available in new mission" do
    @form = create(:form, mission: @mission1)

    # add this user to the other mission so the form index will be accessible
    @user.assignments.create!(mission: @mission2, role: "coordinator")

    assert_redirect_after_mission_change_from(
      from: "/en/m/mission1/responses/new?form_id=#{@form.id}",
      to: "/en/m/mission2"
    )
  end

  it "user should be redirected to home screen if current screen not permitted under new mission" do
    # add the user to the other mission as an enumerator so that the option_sets listing won't be allowed
    @user.assignments.create!(mission: @mission2, role: "enumerator")

    assert_redirect_after_mission_change_from(
      from: "/en/m/mission1/option-sets",
      to: "/en/m/mission2")
  end

  describe "missionchange flag" do
    it "should be removed cleanly if its the only query string arg" do
      get("/en?missionchange=1")
      expect(response).to redirect_to("/en")
    end

    it "should be removed cleanly if its the first of several args" do
      get("/en?missionchange=1&foo=bar")
      expect(response).to redirect_to("/en?foo=bar")
    end

    it "should be removed cleanly if its the last of several args" do
      get("/en?foo=bar&missionchange=1")
      expect(response).to redirect_to("/en?foo=bar")
    end

    it "should be removed cleanly if its in the middle several args" do
      get("/en?foo=bar&missionchange=1&bar=foo")
      expect(response).to redirect_to("/en?foo=bar&bar=foo")
    end
  end

  def assert_redirect_after_mission_change_from(params)
    login(@user)

    get_s(params[:from])

    # Then do a request for the same path but different mission
    # and make sure the redirect afterward is correct.
    get(params[:from].gsub("mission1", "mission2"), params: {missionchange: 1})

    expect(flash[:error]).to be_nil, "Should be no error message for mission change redirects"

    # We should expect a redirect to remove the missionchange param
    expect(response).to be_redirect
    follow_redirect!
    expect(request.url).not_to match(/missionchange/)

    if params[:no_redirect]
      expect(response).to be_success
    else
      expect(response).to redirect_to(params[:to])
      follow_redirect!
      expect(response).to be_success
    end
  end
end
