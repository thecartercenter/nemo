require "spec_helper"

feature "users flow" do
  let(:admin) { create(:admin) }
  let(:mission) { Mission.first }

  before do
    login(admin)
  end

  scenario "create should work" do
    visit "/en/m/#{mission.compact_name}/users/new"
    fill_in "Full Name", with: "Foo Bar"
    fill_in "Username", with: "foobar"
    fill_in "Email", with: "foo@bar.com"
    select "Observer", from: "user_assignments_attributes_0_role"
    choose "Send email instructions"
    click_button "Save"
    expect(page).to have_content("Success: User created successfully")

    # Make sure password email url is correct and no missing translations
    email = ActionMailer::Base.deliveries.last
    expect(email.body.to_s).to match %r{^https?://.+/en/password-resets/\w+/edit$}
    expect(email.body.to_s).not_to match /translation_missing/
  end
end
