# frozen_string_literal: true

require "rails_helper"

feature "user", js: true do
  let(:admin) { create(:admin) }
  let(:mission_name) { get_mission.compact_name }

  before { login(admin) }

  scenario "new admin login flow" do
    # logged in admin creates new admin
    visit "/en/admin/users/new"
    fill_in("* Full Name", with: "Jay Ita")
    fill_in("* Username", with: "foodie")
    fill_in("Email", with: "jay@ita.com")
    select("Enter a new password", from: "Password Creation")
    fill_in("Password", with: "Xxxxxxxx1")
    fill_in("Retype Password", with: "Xxxxxxxx1")
    check("Is Admin?")
    click_on "Save"

    # logged in admin user signs out
    find("i.fa-sign-out").click

    # newly created admin logs in
    visit root_path
    within("form#new_user_session") do
      fill_in("Username", with: "foodie")
      fill_in("Password", with: "Xxxxxxxx1")
      click_on "Login"
    end

    # newly created admin is redirected to root page on successful save
    expect(page).to have_content("Option Sets")
    expect(page).not_to have_content("Edit Profile")
  end
end
