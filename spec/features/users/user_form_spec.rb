# frozen_string_literal: true

require "rails_helper"

feature "user form" do
  let(:admin) { create(:admin) }
  let(:mission) { Mission.first }

  before do
    login(admin)
  end

  scenario "create should work" do
    visit("/en/m/#{mission.compact_name}/users/new")

    # check for placeholders since they have not yet been overwritten
    expect(page).to have_field("Main Phone", placeholder: "+17123241235")
    expect(page).to have_field("Alternate Phone", placeholder: "+2348123456789")

    fill_in("Full Name", with: "Foo Bar")
    fill_in("Username", with: "foobar")
    fill_in("Email", with: "foo@bar.com")
    fill_in("Main Phone", with: "+17094554098")
    fill_in("Alternate Phone", with: "+2347033772211")
    select("Enumerator", from: "user_assignments_attributes_0_role")
    select("Send password reset instructions via email", from: "user_reset_password_method")
    click_button("Save")
    expect(page).to have_content("Success: User created successfully")

    # Make sure password email url is correct and no missing translations
    email = ActionMailer::Base.deliveries.last
    expect(email.body.to_s).to match(%r{^https?://.+/en/password-resets/\w+/edit$})
    expect(email.body.to_s).not_to match(/translation_missing/)
  end
end
