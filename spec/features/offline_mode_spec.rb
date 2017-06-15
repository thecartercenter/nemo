require "spec_helper"

feature "offline mode" do
  let(:user) { create(:admin) }

  around do |example|
    configatron.offline_mode = true
    example.run
    configatron.offline_mode = false
  end

  scenario "forgot password link" do
    visit "/"
    expect(page).not_to have_content("Forgot Password?")
  end

  scenario "broadcast links" do
    login(user)
    click_on("Broadcasts")
    expect(page).not_to have_content("Send Broadcast")
    click_on("Users")
    expect(page).not_to have_content("Send Broadcast")
  end
end
