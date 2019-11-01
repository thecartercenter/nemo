# frozen_string_literal: true

require "rails_helper"

feature "form status display and changes", js: true do
  let!(:form) { create(:form, :draft, name: "Myform") }
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  scenario "changing status via index page" do
    visit(forms_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    expect(page).to have_css("tr", text: /Myform Draft/)

    click_link("Go Live")
    expect(page).to have_css("tr", text: /Myform Live/)

    click_link("Pause")
    expect(page).to have_css("tr", text: /Myform Paused/)
  end

  scenario "changing status via edit page" do
    visit(forms_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    click_link("Myform")
    expect(page).to have_css("div#status", text: /Status Draft/)
    expect(page).to have_css(".top-action-links a", text: /Delete/)
    expect(page).to have_css(".top-action-links a", text: /Go Live/)

    click_link("Go Live")
    click_link("Myform")
    expect(page).to have_css("div#status", text: /Status Live/)
    expect(page).not_to have_css(".top-action-links a", text: /Delete/)
    expect(page).to have_css(".top-action-links a", text: /Pause/)

    click_link("Pause")
    click_link("Myform")
    expect(page).to have_css("div#status", text: /Status Paused/)
    expect(page).not_to have_css(".top-action-links a", text: /Delete/)
    expect(page).to have_css(".top-action-links a", text: /Go Live/)
  end

  scenario "changing status via save and go live button" do
    visit(new_form_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    expect(page).to have_css("div#status", text: /Status Draft/)
    fill_in("Name", with: "Yourform")

    click_button("Save")
    expect(page).to have_content("Form created successfully")
    expect(page).to have_css("div#status", text: /Status Draft/)

    click_button("Save and Go Live")
    click_link("Yourform")
    expect(page).to have_css("div#status", text: /Status Live/)
    expect(page).not_to have_content("Save and Go Live")

    click_link("Pause")
    click_link("Yourform")
    expect(page).to have_css("div#status", text: /Status Paused/)

    click_button("Save and Go Live")
    click_link("Yourform")
    expect(page).to have_css("div#status", text: /Status Live/)
  end
end
