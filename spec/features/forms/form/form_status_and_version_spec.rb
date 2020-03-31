# frozen_string_literal: true

require "rails_helper"

feature "form status and version display and changes", js: true do
  let!(:form) { create(:form, :draft, name: "Myform") }
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  scenario "changing status via index page" do
    visit(forms_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    expect(page).to have_css("tr", text: /Myform\nDraft/)

    click_link("Go Live")
    expect(page).to have_css("tr", text: /Myform\n Live/)

    click_link("Pause")
    expect(page).to have_css("tr", text: /Myform\n Paused/)
  end

  scenario "changing status and version via edit page" do
    visit(forms_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    click_link("Myform")
    expect(page).to have_css(".top-action-links a", text: /Delete/)
    expect(page).to have_css(".top-action-links a", text: /Go Live/)
    expect(page).not_to have_css(".top-action-links a", text: /Pause/)
    expect(page).not_to have_css(".top-action-links a", text: /Return to Draft Status/)
    click_link("More settings")
    expect(page).to have_css("div#status", text: /Status\nDraft/)
    expect(page).not_to have_content("Current Version")
    expect(page).not_to have_content("Minimum Accepted Version")

    click_link("Go Live")
    expect(page).not_to have_css(".top-action-links a", text: /Delete/)
    expect(page).not_to have_css(".top-action-links a", text: /Go Live/)
    expect(page).to have_css(".top-action-links a", text: /Pause/)
    expect(page).to have_css(".top-action-links a", text: /Return to Draft Status/)
    expect(page).to have_css("div#status", text: /Status\n Live/)
    click_link("More settings")
    version1 = find("div#current_version_name .regenerable-field span").text
    expect(page).to have_select("Minimum Accepted Version", selected: version1)

    # Increment version should change current version but not min version.
    accept_confirm { click_link("Increment Version") }
    expect(page).to have_css("i.success")
    expect(page).to have_select("Minimum Accepted Version", selected: version1) # Shouldn't change
    version2 = find("div#current_version_name .regenerable-field span").text
    expect(version2).not_to eq(version1)
    select(version2, from: "Minimum Accepted Version")
    click_button("Save")

    # New min version should be persisted.
    expect(page).to have_content("Current Version\n#{version2}")
    click_link("More settings")
    expect(page).to have_select("Minimum Accepted Version", selected: version2)

    # Switch back to older version.
    select(version1, from: "Minimum Accepted Version")
    click_button("Save")
    click_link("More settings")
    expect(page).to have_select("Minimum Accepted Version", selected: version1)

    click_link("Pause")
    expect(page).to have_css("div#status", text: /Status\n Paused/)
    expect(page).not_to have_css(".top-action-links a", text: /Delete/)
    expect(page).to have_css(".top-action-links a", text: /Go Live/)
    expect(page).not_to have_css(".top-action-links a", text: /Pause/)
    expect(page).to have_css(".top-action-links a", text: /Return to Draft Status/)

    click_link("Return to Draft Status")
    fill_in("override", with: "override")
    click_button("Cancel")
    expect(page).to have_css("div#status", text: /Status\n Paused/)

    click_link("Return to Draft Status")
    expect(page).to have_field("override", text: "")
    fill_in("override", with: "override")
    click_button("Accept Risks & Change Status")
    expect(page).to have_css("div#status", text: /Status\nDraft/)
    click_link("More settings")
    expect(page).to have_content("Current Version\n#{version2}")
    expect(page).to have_select("Minimum Accepted Version", selected: version1)

    # Going live again shouldn't change versions
    click_link("Go Live")
    expect(page).to have_css("div#status", text: /Status\n Live/)
    expect(page).to have_content("Current Version\n#{version2}")
    click_link("More settings")
    expect(page).to have_select("Minimum Accepted Version", selected: version1)
  end

  scenario "changing status via save and go live button" do
    visit(new_form_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    expect(page).to have_css("div#status", text: /Status\nDraft/)
    fill_in("Name", with: "Yourform")

    click_button("Save")
    expect(page).to have_content("Form created successfully")
    expect(page).to have_css("div#status", text: /Status\nDraft/)

    click_button("Save and Go Live")
    click_link("Yourform")
    expect(page).to have_css("div#status", text: /Status\n Live/)
    expect(page).not_to have_content("Save and Go Live")

    click_link("Pause")
    expect(page).to have_css("div#status", text: /Status\n Paused/)

    click_button("Save and Go Live")
    click_link("Yourform")
    expect(page).to have_css("div#status", text: /Status\n Live/)
  end
end
