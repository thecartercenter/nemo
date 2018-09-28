# frozen_string_literal: true

require "rails_helper"

feature "user", js: true do
  let(:mission) { get_mission }
  let(:admin) { create(:admin, mission: mission) }

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
    find(".add_assignment").click
    select(mission.name, from: "user[assignments_attributes][0][mission_id]")
    select("Coordinator", from: "user[assignments_attributes][0][role]")
    click_on "Save"

    # logged in admin user signs out
    find("i.fa-sign-out").click

    # newly created admin logs in
    fill_login_form

    # on the edit page
    expect(page).to have_content("Edit Profile")
    click_on "Save"

    # newly created admin is redirected to root page on successful profile save
    user_is_on_root_page

    # newly created logs out
    find("i.fa-sign-out").click

    # newly created admin is redirected straight to the root page on login
    fill_login_form
    user_is_on_root_page
  end

  def fill_login_form
    visit(root_path)
    within("form#new_user_session") do
      fill_in("Username", with: "foodie")
      fill_in("Password", with: "Xxxxxxxx1")
      click_on "Login"
    end
  end

  def user_is_on_root_page
    expect(page).to have_content("Option Sets")
    expect(page).not_to have_content("Edit Profile")
  end
end
