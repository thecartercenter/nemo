# frozen_string_literal: true

require "rails_helper"

feature "switching between missions and modes", js: true do
  let!(:mission1) { create(:mission) }
  let!(:mission2) { create(:mission) }
  let!(:user) { create(:user, mission: mission1) }
  let!(:form) { create(:form, mission: mission1) }

  before do
    user.assignments.create!(mission: mission2, role: "coordinator")
    login(user)
  end

  scenario "should work" do
    # Test that changing to mission1 from mission2 root works.
    visit(forms_path(mode: "m", mission_name: mission2.compact_name, locale: "en"))
    expect(current_url).to match("/m/#{mission2.compact_name}")
    select(mission1.name, from: "change-mission")
    expect(page).to have_selector("#logo h2", text: /#{mission1.name}/i)

    # Smart redirect on mission change should work.
    # (Note this the controller logic for this is extensively tested
    # in mission_change_redirect_spec but this test
    # ensures that the missionchange parameter is getting set by JS, etc.)
    click_link("Forms")
    click_link(form.name)
    expect(page).to have_selector("h1.title", text: form.name)
    select(mission2.name, from: "change-mission")
    expect(page).to have_selector("h1.title", text: "Forms")

    # Changing mission from unauthorized page should work.
    visit("/en/unauthorized")
    select(mission1.name, from: "change-mission")
    expect(page).to have_selector("#logo h2", text: /#{mission1.name}/i)
  end
end
