# frozen_string_literal: true

require "rails_helper"

feature "dashboard", js: true do
  let(:dashboard_path) { mission_root_path(mission_name: get_mission.compact_name, locale: "en") }

  before do
    login(user)
  end

  context "with staffer" do
    let(:user) { create(:user, role_name: "staffer") }
    let(:enum1) { create(:user, role_name: "enumerator", name: "Florian") }
    let(:enum2) { create(:user, role_name: "enumerator", name: "Gizzard") }
    let!(:form) { create(:form, question_types: %w[text]) }
    let!(:response) { create(:response, answer_values: %w[foo], user: enum1) }
    let!(:report) do
      create(:response_tally_report, name: "Reppy", _calculations: ["source"])
    end

    scenario "ajax reload should work" do
      visit(dashboard_path)
      click_link("Reload via AJAX")
      wait_for_ajax
    end

    scenario "report chooser should work" do
      visit(dashboard_path)
      expect(page).to have_content("Select a report above")
      expect(page).not_to have_content("Source")

      first(".report-chooser").select("Reppy")
      expect(page).to have_content("Source")

      first("a.action-link-close").click
      expect(page).to have_content("Select a report above")
      expect(page).not_to have_content("Source")
    end

    scenario "new responses should be highlighted" do
      visit(dashboard_path)
      expect(page).to have_content("Florian")
      expect(page).not_to have_highlighted_rows

      create(:response, answer_values: %w[bar], user: enum2)
      click_link("Reload via AJAX")

      new_row = first(".recent-responses-table tr[style]", text: "Gizzard")
      expect(new_row["style"]).to match(/background-color/)
      sleep(4.1) # Allow highlight to dissipate
      expect(page).not_to have_highlighted_rows

      click_link("Reload via AJAX")
      wait_for_ajax
      expect(page).not_to have_highlighted_rows
    end
  end

  context "with user that can't see dashboard" do
    let(:user) { create(:user, role_name: "enumerator") }

    scenario "it should redirect to responses page" do
      visit(dashboard_path)
      expect(page).to have_css(:h1, text: "Responses")
    end
  end

  def have_highlighted_rows
    have_css(".recent-responses-table tr[style*=background]")
  end
end
