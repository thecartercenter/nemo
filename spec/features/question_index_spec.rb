# frozen_string_literal: true

require "rails_helper"

feature "question index", js: true do
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "batch delete" do
    let!(:questions) { create_list(:question, 3, mission: mission) }

    scenario "works" do
      visit("/en/m/#{mission.compact_name}/questions")
      all("input.batch_op").each { |b| b.set(true) }
      accept_confirm { click_on("Delete Multiple Questions") }
      expect(page).to have_content("3 questions deleted successfully")
    end

    scenario "redirects correctly after batch delete" do
      visit("/en/m/#{mission.compact_name}/questions")

      save_and_open_page
    end
  end
end
