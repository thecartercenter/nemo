# frozen_string_literal: true

require "rails_helper"

feature "question index", js: true do
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }
  let!(:questions) { create_list(:question, 3, canonical_name: "duplicated", mission: mission) }

  before do
    login(admin)
  end

  describe "bulk destroy" do
    scenario "works" do
      visit("/en/m/#{mission.compact_name}/questions")
      perform_bulk_destroy
      expect(page).to have_content("3 questions deleted successfully")
    end

    scenario "redirects correctly after bulk destroy" do
      visit("/en/m/#{mission.compact_name}/questions")

      # do a search
      fill_in class: "search-str", with: "dup"
      click_on "Search"

      # clear search box
      click_on "Clear"

      # perform a bulk destroy
      perform_bulk_destroy

      # page redirects without query string
      expect(page).to have_current_path("/en/m/#{mission.compact_name}/questions")
    end
  end

  def perform_bulk_destroy
    all("input.batch_op").each { |b| b.set(true) }
    accept_confirm { click_on("Delete Multiple Questions") }
  end
end
