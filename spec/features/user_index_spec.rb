# frozen_string_literal: true

require "rails_helper"

feature "user index", js: true do
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "batch delete" do
    let!(:users) { create_list(:user, 3, mission: mission) }

    scenario do
      visit("/en/m/#{mission.compact_name}/users")
      all("input.batch_op").each { |b| b.set(true) }
      accept_confirm { click_on("Delete Multiple Users") }
      expect(page).to have_content("3 users deleted successfully")
    end
  end
end
