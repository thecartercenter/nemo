# frozen_string_literal: true

require "rails_helper"

feature "dashboard", js: true do
  before do
    login(user)
  end

  context "with staffer" do
    let(:user) { create(:user, role_name: "staffer") }

    before do
      visit(mission_root_path(mission_name: get_mission.compact_name, locale: "en"))
    end

    scenario "ajax reload should work" do
      click_link("Reload via AJAX")
      wait_for_ajax
      expect(page).to have_content("LATEST RESPONSES")
    end
  end

  context "with user that can't see dashboard" do
    let(:user) { create(:user, role_name: "enumerator") }

    scenario "it should redirect to responses page" do
      visit(mission_root_path(mission_name: get_mission.compact_name, locale: "en"))
      expect(page).to have_css(:h1, text: "Responses")
    end
  end
end
