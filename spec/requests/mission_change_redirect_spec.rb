# frozen_string_literal: true

require "rails_helper"

describe "redirect on mission change" do
  let(:mission1) { create(:mission, name: "Mission1") }
  let(:mission2) { create(:mission, name: "Mission2") }
  let(:user) { create(:user, mission: mission1, role_name: :coordinator) }

  it "user should not be redirected if on object listing and has permission" do
    # add this user to the other mission so the form index will be accessible
    user.assignments.create!(mission: mission2, role: "coordinator")
    assert_redirect_after_mission_change_from(from: "/en/m/mission1/forms", no_redirect: true)
  end

  context "viewing object that is mission based and not linked to new current mission" do
    # Add this user to the other mission so the form index will be accessible.
    before { user.assignments.create!(mission: mission2, role: "coordinator") }

    %w[form question option_set user].each do |type|
      it "user should be redirected to object listing for #{type}" do
        assert_redirect_for(type)
      end
    end

    it "user should be redirected to object listing for questioning" do
      assert_redirect_for("questioning", to_root: true)
    end

    it "user should be redirected to object listing for response" do
      assert_redirect_for("response", identifier: :shortcode)
    end

    it "user should be redirected to object listing for broadcast" do
      assert_redirect_for("broadcast", traits: [:with_recipient_users], no_edit: true)
    end

    it "user should be redirected to object listing for report" do
      assert_redirect_for("standard_form_report", path_chunk: "reports")
    end
  end

  it "user should be redirected to home screen if was viewing object but redirect to object listing is not permitted" do
    option_set = create(:option_set, mission: mission1)

    # add the user to the other mission as an enumerator so that the option_sets listing won't be allowed
    user.assignments.create!(mission: mission2, role: "enumerator")

    assert_redirect_after_mission_change_from(
      from: "/en/m/mission1/option-sets/#{option_set.id}",
      to: "/en/m/mission2"
    )
  end

  it "user should be redirected to home screen if viewing new response but form not available in new mission" do
    form = create(:form, mission: mission1)

    # add this user to the other mission so the form index will be accessible
    user.assignments.create!(mission: mission2, role: "coordinator")

    assert_redirect_after_mission_change_from(
      from: "/en/m/mission1/responses/new?form_id=#{form.id}",
      to: "/en/m/mission2"
    )
  end

  it "user should be redirected to home screen if current screen not permitted under new mission" do
    # add the user to the other mission as an enumerator so that the option_sets listing won't be allowed
    user.assignments.create!(mission: mission2, role: "enumerator")

    assert_redirect_after_mission_change_from(
      from: "/en/m/mission1/option-sets",
      to: "/en/m/mission2"
    )
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

  def assert_redirect_for(type, path_chunk: nil, to_root: false, identifier: :id, traits: [], no_edit: false)
    obj = create(type, *traits, mission: mission1)

    path_chunk ||= type.tr("_", "-") << "s"
    from = "/en/m/mission1/#{path_chunk}/#{obj.send(identifier)}"
    to = to_root ? "/en/m/mission2" : "/en/m/mission2/#{path_chunk}"

    assert_redirect_after_mission_change_from(from: from, to: to)
    return if no_edit
    assert_redirect_after_mission_change_from(from: "#{from}/edit", to: to)
  end

  def assert_redirect_after_mission_change_from(from:, to: nil, no_redirect: false)
    login(user)

    get(from)

    # Then do a request for the same path but different mission
    # and make sure the redirect afterward is correct.
    get(from.gsub("mission1", "mission2"), params: {missionchange: 1})

    expect(flash[:error]).to be_nil, "Should be no error message for mission change redirects"

    # We should expect a redirect to remove the missionchange param
    expect(response).to be_redirect
    follow_redirect!
    expect(request.url).not_to match(/missionchange/)

    # Test subsequent redirect, if any.
    if no_redirect
      expect(response).to be_successful
    else
      expect(response).to redirect_to(to)
    end
  end
end
