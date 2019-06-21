# frozen_string_literal: true

require "rails_helper"

feature "broadcasts", :sms, js: true do
  include_context "search"
  let(:max_user_dropdown_results) { BroadcastsController::USERS_OR_GROUPS_PER_PAGE * 2 }
  let!(:user) { create(:user, role_name: "staffer") }
  let!(:users) { create_list(:user, max_user_dropdown_results, role_name: "enumerator") }
  let!(:user2) { create(:user, name: "Zied") }
  let!(:decoy_user) { create(:user, name: "Decoy") }

  before do
    login(user)
  end

  scenario "via broadcast index" do
    visit(broadcasts_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    click_link("Send Broadcast")

    # Validation should kick in if form empty.
    click_button("Send")
    expect(page).to have_content("This field is required. Nobody would receive this broadcast.")

    # Fill out form this time.
    select("Both SMS and email", from: "Medium")
    select("Specific users", from: "Recipients")

    # Because there are more users in the DB than shown in the list, and we know Zied will be at the
    # end, if we search for him and we can actually click him, we know the search works.
    select2("User: #{user2.name}", from: "broadcast_recipient_ids", search: "zie")

    select("Main phone only", from: "Which Phone")
    fill_in("Message", with: "foo bar baz")
    click_button("Send")
    expect(page).to have_content("Broadcast queued")
    expect(page).to have_content(user2.name)
  end

  describe "via user index" do
    context "with one page of users" do
      scenario "select all shows as 'all users in mission'" do
        visit(users_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        click_link("Select All")
        click_link("Send Broadcast")
        fill_message_and_send
        expect(page).to have_content("Broadcast queued")
        expect(page).to have_content("All users in mission")
      end

      scenario "only two users selected  shows as 'specific users'" do
        visit(users_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        check("selected_#{user.id}")
        check("selected_#{user2.id}")
        click_link("Send Broadcast")
        fill_message_and_send
        expect(page).to have_text("Broadcast queued")
        expect(page).to have_content(user.name)
        expect(page).to have_content(user2.name)
        expect(page).not_to have_content(decoy_user.name)
        expect(page).to have_content("Specific users/groups in mission")
      end

      scenario "filtered select all shows as 'specific users'" do
        visit(users_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        search_for("role:staffer")
        click_link("Select All")
        click_link("Send Broadcast")
        fill_message_and_send
        expect(page).to have_text("Broadcast queued")
        expect(page).to have_content(user.name)
        expect(page).not_to have_content(user2.name)
        expect(page).to have_content("Specific users/groups in mission")
      end
    end

    context "with multiple pages of users" do
      before do
        stub_const(UsersController, "PER_PAGE", 3)
      end

      scenario "unfiltered select all users on page shows as 'specific users'" do
        visit(users_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        click_link("Select All")
        click_link("Send Broadcast")
        fill_message_and_send
        expect(page).to have_text("Broadcast queued")
        expect(page).to have_content("Specific users/groups in mission")
      end

      scenario "unfiltered select all users available shows as 'all users in mission'" do
        visit(users_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        click_link("Select All")
        click_link("Select all 13 Users")
        click_link("Send Broadcast")
        fill_message_and_send
        expect(page).to have_text("Broadcast queued")
        expect(page).to have_text("All users in mission")
      end

      scenario "filtered select all users available shows as 'specific users'" do
        visit(users_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        search_for("role:enumerator")
        click_link("Select All")
        click_link("Select all 10 Users")
        click_link("Send Broadcast")
        fill_message_and_send
        expect(page).to have_text("Broadcast queued")
        expect(page).to have_content("Specific users/groups in mission")
      end
    end
  end

  private

  def fill_message_and_send
    select("Both SMS and email", from: "broadcast_medium")
    select("Main phone only", from: "broadcast_which_phone")
    fill_in("Message", with: "foo bar baz")
    click_button("Send")
  end
end
