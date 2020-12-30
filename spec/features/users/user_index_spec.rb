# frozen_string_literal: true

require "rails_helper"

feature "user index", js: true do
  let(:mission) { get_mission }
  let(:actor) { create(:user, role_name: :coordinator) }
  let!(:user1) { create(:user, name: "Apple", login: "apple") }
  let!(:user2) { create(:user, name: "Banana", login: "banana") }
  let!(:user3) { create(:user, name: "Cumquat", login: "cumquat") }

  before do
    login(actor)
  end

  describe "add/remove to/from group" do
    context "with no groups" do
      scenario do
        visit("/en/m/#{mission.compact_name}/users")
        click_link("Add to Group")
        expect(page).to have_content("You haven't selected")
        expect(page).not_to have_css(".user-groups-modal")

        find("tr", text: "Apple").find("input[type=checkbox]").check
        click_link("Add to Group")
        expect(page).to have_css("#user-groups-modal", text: "There are currently no user groups")
        find("#user-groups-modal [data-dismiss=modal]").click
        expect(page).not_to have_css("#user-groups-modal")

        click_link("Remove from Group")
        expect(page).to have_css("#user-groups-modal", text: "There are currently no user groups")
      end
    end

    context "with existing groups" do
      let!(:group1) { create(:user_group, name: "Group1") }
      let!(:group1) { create(:user_group, name: "Group2") }

      scenario do
        visit("/en/m/#{mission.compact_name}/users")
        find("tr", text: "Apple").find("input[type=checkbox]").check
        find("tr", text: "Banana").find("input[type=checkbox]").check
        click_link("Add to Group")
        find("#user-groups-modal select").select("Group2")
        click_button("Add to Group")

        expect(page).to have_flash_success("Successfully added 2 users to group Group2")
        expect(page).to have_content(/Apple\s*apple\s*Group2/)
        expect(page).to have_content(/Banana\s*banana\s*Group2/)
        expect(page).to have_content(/Cumquat\s*cumquat/)
        expect(page).not_to have_content(/Cumquat\s*cumquat\s*Group2/)

        click_link("Select All")
        click_link("Remove from Group")
        find("#user-groups-modal select").select("Group2")
        click_button("Remove from Group")

        expect(page).to have_flash_success("Successfully removed 4 users from group Group2")
        expect(page).not_to have_css(".index-table", text: "Group2")
      end
    end
  end
end
