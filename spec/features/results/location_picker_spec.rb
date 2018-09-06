# frozen_string_literal: true

require "rails_helper"

feature "response form location picker", js: true do
  include_context "response tree"

  let(:user) { create(:user) }
  let!(:form) { create(:form, :published, question_types: %w[location]) }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

  before { login(user) }

  scenario "picking a location" do
    visit new_hierarchical_response_path(params)

    # open the location picker
    find(".action_link_drop_pin").click
    expect(page).to have_content("Choose Location")

    # search for a location
    find(".location-search input").set("Ithaca").send_keys(:return)

    # select a result
    click_link("Ithaca, NY, USA")

    click_button("Accept")
    expect(page).to_not have_content("Choose Location")

    expect_value([0], "42.443961 -76.501881")

    fill_in_question([0], with: "12 34")
    find(".action_link_drop_pin").click
    expect(page).to have_content("Current Location: 12.000000 34.000000")
  end
end
