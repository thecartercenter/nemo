# frozen_string_literal: true

require "rails_helper"

feature "user form", js: true do
  let(:admin) { create(:admin) }
  let!(:mission) { create(:mission) }

  before do
    login(admin)
  end

  context "admin user in mission mode" do
    scenario "create and edit user should work" do
      visit("/en/m/#{mission.compact_name}/users/new")

      # check for placeholders since they have not yet been overwritten
      expect(page).to have_field("Main Phone", placeholder: "e.g. +17123241235")
      expect(page).to have_field("Alternate Phone", placeholder: "e.g. +2348123456789")

      fill_in("Full Name", with: "Foo Bar")
      fill_in("Username", with: "foobar")
      fill_in("Email", with: "foo@bar.com")
      fill_in("Main Phone", with: "+17094554098")
      fill_in("Alternate Phone", with: "+2347033772211")
      select("Enumerator", from: "user_assignments_attributes_0_role")
      select("Send password reset instructions via email", from: "user_reset_password_method")
      emails = emails_sent_by { click_button("Save") }
      expect(page).to have_content("Success: User created successfully")

      # Make sure password email url is correct and no missing translations
      expect(emails.length).to eq(1)
      email = emails.first
      expect(email.body.to_s).to match(%r{^https?://.+/en/password-resets/[\w_-]+/edit$})
      expect(email.body.to_s).not_to match(/translation_missing/)

      # Go to edit and change something
      click_link("Foo Bar")
      select("Staffer", from: "user_assignments_attributes_0_role")
      click_button("Save")

      # Go to show page
      click_link("View")
      expect(page).to have_content("Staffer")
      expect(page).to have_content("foo@bar.com")
      expect(page).to have_content("Foo Bar")
    end
  end

  context "admin user in admin mode" do
    scenario "create and edit user should work" do
      visit("/en/admin/users/new")
      fill_in("Full Name", with: "Ella Baker")
      fill_in("Username", with: "ellab")
      fill_in("Email", with: "ella@baker.com")
      find("a", text: "Add Assignment").click
      select("Staffer", from: "user[assignments_attributes][0][role]")
      click_on("Save")
      expect(page).to have_content("Success: User created successfully")

      # Edit user and change assignment
      click_link("Ella Baker")
      select("Reviewer", from: "user[assignments_attributes][0][role]")
      click_on("Save") # Redirects back to edit
      expect(page).to have_content("Success: User updated successfully")

      # Verify in show mode
      click_link("View")
      expect(page).to have_content("Reviewer")
    end
  end
end
