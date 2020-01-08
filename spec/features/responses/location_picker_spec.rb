# frozen_string_literal: true

require "rails_helper"

feature "response form location picker", js: true do
  include_context "response tree"

  let(:user) { create(:user) }
  let!(:form) { create(:form, :live, question_types: %w[location]) }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

  before { login(user) }

  scenario "manually entering invalid location" do
    visit new_response_path(params)

    fill_in("Location Question Title", with: "invalid")
    click_button("Save")

    expect(page).to have_content("Response is invalid")
    expect(page).to have_content("Latitude is out of range")
    expect(page).to have_content("Longitude is out of range")
  end

  scenario "picking a location" do
    visit new_response_path(params)

    # open the location picker
    find(".action-link-drop-pin").click
    expect(page).to have_content("Choose Location")

    # search for a location
    find(".location-search input").set("Joe Batt's Arm").send_keys(:return)

    # select a result
    click_link("Joe Batt's Arm", match: :first)

    click_button("Accept")
    expect(page).not_to have_content("Choose Location")

    expect_value([0], "49.726683 -54.173526")

    fill_in_question([0], with: "12 34")
    find(".action-link-drop-pin").click
    expect(page).to have_content("Current Location: 12.000000 34.000000")
  end
end
