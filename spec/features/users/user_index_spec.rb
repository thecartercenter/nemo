# frozen_string_literal: true

require "rails_helper"

feature "user index", js: true do
  include_context "search"
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "bulk destroy not paginated" do
    let!(:coordinators) { create_list(:user, 5, mission: mission) }
    let!(:enumerators) { create_list(:user, 5, mission: mission, role_name: :enumerator) }

    scenario "unfiltered" do
      visit("/en/m/#{mission.compact_name}/users")
      click_on("Select All")
      click_on("Delete Multiple Users")
      expect(accept_alert).to eq("Are you sure you want to delete these 11 users?")
      expect(page).to have_content("10 users deleted successfully")
    end

    scenario "filtered" do
      visit("/en/m/#{mission.compact_name}/users")
      search_for("role:enumerator")
      click_on("Select All")
      click_on("Delete Multiple Users")
      expect(accept_alert).to eq("Are you sure you want to delete these 5 users?")
      expect(page).to have_content("5 users deleted successfully")
    end

    scenario "do not select anything" do
      visit("/en/m/#{mission.compact_name}/users")
      click_on("Delete Multiple Users")
      expect(page).to have_content("You haven't selected anything")
    end
  end

  describe "bulk destroy paginated" do
    let!(:coordinators) { create_list(:user, 55, mission: mission) }
    let!(:enumerators) { create_list(:user, 55, mission: mission, role_name: :enumerator) }

    scenario "unfiltered select page" do
      visit("/en/m/#{mission.compact_name}/users")
      click_on("Select All")
      click_on("Delete Multiple Users")
      expect(accept_alert).to eq("Are you sure you want to delete these 50 users?")
      expect(page).to have_content("49 users deleted successfully")
    end

    scenario "unfiltered select all" do
      visit("/en/m/#{mission.compact_name}/users")
      click_on("Select All")
      click_on("Select all 111 Users")
      click_on("Delete Multiple Users")
      expect(accept_alert).to eq("Are you sure you want to delete these 111 users?")
      expect(page).to have_content("110 users deleted successfully")
    end

    scenario "filtered select page" do
      visit("/en/m/#{mission.compact_name}/users")
      search_for("role:enumerator")
      click_on("Select All")
      click_on("Delete Multiple Users")
      expect(accept_alert).to eq("Are you sure you want to delete these 50 users?")
      expect(page).to have_content("50 users deleted successfully")
    end

    # this is currently not working, doesn't pass filter scope to delete
    # should remove functionality to select all within a filter?
    # scenario "filtered select all" do
    #   visit("/en/m/#{mission.compact_name}/users")
    #   search_for("role:enumerator")
    #   click_on("Select All")
    #   click_on("Select all 55 Users")
    #   click_on("Delete Multiple Users")
    #   expect(accept_alert).to eq("Are you sure you want to delete these 55 users?")
    #   expect(page).to have_content("55 users deleted successfully")
    # end
  end
end
