require 'spec_helper'

feature 'broadcasts flow', js: true do
  let!(:user) { create(:user, role_name: "staffer") }
  let!(:user2) { create(:user) }

  before { login(user) }

  scenario "happy path" do
    click_link("Broadcasts")
    click_link("Send Broadcast")
    select("Both SMS and email", from: "Medium")
    select("Specific users", from: "Recipients")
    select2(user2.name, from: "broadcast_recipient_ids")
    select("Main phone only", from: "Which Phone")
    fill_in("Message", with: "foo bar baz")
    click_button("Send")
    expect(page).to have_content("Broadcast sent successfully")
  end

  scenario "happy path via users list" do
    click_link("Users")
    click_link("Select All")
    click_link("Send Broadcast")
    select("Both SMS and email", from: "Medium")
    select("Main phone only", from: "Which Phone")
    fill_in("Message", with: "foo bar baz")
    click_button("Send")
    expect(page).to have_content("Broadcast sent successfully")
    expect(page).to have_content("All users in mission")
  end
end
