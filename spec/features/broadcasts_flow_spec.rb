require 'rails_helper'

feature 'broadcasts flow', :sms, js: true do
  let!(:user) { create(:user, role_name: "staffer") }
  let!(:users) { create_list(:user, 10) }
  let!(:user2) { create(:user, name: "Zied") }

  before do
    login(user)
  end

  scenario "happy path" do
    click_link("Broadcasts")
    click_link("Send Broadcast")
    select("Both SMS and email", from: "Medium")
    select("Specific users", from: "Recipients")
    select2("User: #{user2.name}", from: "broadcast_recipient_ids", search: "z")
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

  scenario "happy path via users list with specific users selected" do
    click_link("Users")
    check("selected_#{user.id}")
    check("selected_#{user2.id}")
    click_link("Send Broadcast")
    select("Both SMS and email", from: "broadcast_medium")
    select("Main phone only", from: "broadcast_which_phone")
    fill_in("Message", with: "foo bar baz")
    click_button("Send")
    expect(page).to have_text "Broadcast sent successfully"
    expect(page).to have_content(user.name)
    expect(page).to have_content(user2.name)
  end
end
